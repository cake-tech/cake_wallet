import Foundation

#if canImport(Flutter)
import Flutter
#endif

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Thin, model-agnostic wrapper around Apple's on-device Foundation Models.
///
/// It exposes just two primitives to Dart: free-text generation and generation
/// constrained to a small JSON schema. All routing, validation and wallet tool
/// logic lives in Dart (lib/ask_cake), so another backend (for example a
/// downloadable GGUF model) only has to provide these same two primitives.
final class AskCakeModel {
    static let shared = AskCakeModel()

    struct ModelError: Error {
        let code: String
        let message: String
    }

    private var sessions: [String: Any] = [:]
    private let lock = NSLock()

    func availability() -> [String: Any] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            let model = SystemLanguageModel.default
            var info: [String: Any] = ["contextSize": model.contextSize]
            if #available(iOS 27.0, macOS 27.0, *) {
                info["model"] = model.variant.displayName
            } else {
                info["model"] = "Apple Foundation Model"
            }
            switch model.availability {
            case .available:
                info["available"] = true
            case .unavailable(let reason):
                info["available"] = false
                switch reason {
                case .deviceNotEligible: info["reason"] = "deviceNotEligible"
                case .appleIntelligenceNotEnabled: info["reason"] = "appleIntelligenceNotEnabled"
                case .modelNotReady: info["reason"] = "modelNotReady"
                @unknown default: info["reason"] = "unknown"
                }
            @unknown default:
                info["available"] = false
                info["reason"] = "unknown"
            }
            return info
        }
        #endif
        return ["available": false, "reason": "osTooOld"]
    }

    /// - Parameter permissive: use Apple's permissive guardrails, meant for sessions that only
    ///   transform text the app supplies (answering from wallet data or docs excerpts). The default
    ///   guardrails randomly refuse ordinary wallet wording such as "back up my wallet".
    func createSession(instructions: String, permissive: Bool = false) throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            let model = permissive
                ? SystemLanguageModel(guardrails: .permissiveContentTransformations)
                : SystemLanguageModel.default
            let session = LanguageModelSession(model: model, instructions: instructions)
            let id = UUID().uuidString
            lock.lock(); sessions[id] = session; lock.unlock()
            return id
        }
        #endif
        throw ModelError(code: "unavailable", message: "Foundation Models need iOS 26 or later")
    }

    private func storedSession(_ id: String) -> Any? {
        lock.lock(); defer { lock.unlock() }
        return sessions[id]
    }

    func disposeSession(_ id: String) {
        lock.lock(); sessions[id] = nil; lock.unlock()
    }

    /// - Parameter schema: optional `{name, properties: [{name, description?, type, values?, optional?}]}`
    ///   where type is one of string, int, bool, enum. With a schema the reply is a JSON object string.
    func respond(sessionId: String, prompt: String, schema: [String: Any]?) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            guard let session = storedSession(sessionId) as? LanguageModelSession else {
                throw ModelError(code: "noSession", message: "Unknown session")
            }
            let options = GenerationOptions(temperature: 0)
            do {
                if let schema {
                    let generationSchema = try Self.makeSchema(schema)
                    let response = try await session.respond(to: prompt, schema: generationSchema, options: options)
                    return response.content.jsonString
                }
                return try await session.respond(to: prompt, options: options).content
            } catch let error as ModelError {
                throw error
            } catch {
                throw Self.map(error)
            }
        }
        #endif
        throw ModelError(code: "unavailable", message: "Foundation Models need iOS 26 or later")
    }

    #if canImport(Flutter)
    /// Registers the `com.cake_wallet/ask_cake` method channel.
    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "com.cake_wallet/ask_cake", binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            let args = call.arguments as? [String: Any] ?? [:]
            switch call.method {
            case "availability":
                result(shared.availability())
            case "createSession":
                do {
                    result(try shared.createSession(
                        instructions: args["instructions"] as? String ?? "",
                        permissive: args["permissive"] as? Bool ?? false))
                }
                catch let error as ModelError { result(FlutterError(code: error.code, message: error.message, details: nil)) }
                catch { result(FlutterError(code: "generation", message: nil, details: nil)) }
            case "disposeSession":
                shared.disposeSession(args["sessionId"] as? String ?? "")
                result(nil)
            case "respond":
                Task {
                    let outcome: Any?
                    do {
                        outcome = try await shared.respond(
                            sessionId: args["sessionId"] as? String ?? "",
                            prompt: args["prompt"] as? String ?? "",
                            schema: args["schema"] as? [String: Any])
                    } catch let error as ModelError {
                        outcome = FlutterError(code: error.code, message: error.message, details: nil)
                    } catch {
                        outcome = FlutterError(code: "generation", message: nil, details: nil)
                    }
                    DispatchQueue.main.async { result(outcome) }
                }
            case "routerLoad":
                Task {
                    var info: [String: Any] = ["loaded": false, "reason": "osTooOld"]
                    if #available(iOS 18.0, *) { info = await AskCakeRouterModel.shared.load(path: args["path"] as? String) }
                    DispatchQueue.main.async { result(info) }
                }
            case "routerGenerate":
                Task {
                    var outcome: Any? = FlutterError(code: "unavailable", message: nil, details: nil)
                    if #available(iOS 18.0, *) {
                        do {
                            outcome = try await AskCakeRouterModel.shared.generate(
                                ids: args["ids"] as? [Int] ?? [],
                                stops: Set(args["stops"] as? [Int] ?? []),
                                maxNew: args["maxNew"] as? Int ?? 80)
                        } catch { outcome = FlutterError(code: "generation", message: String(describing: type(of: error)), details: nil) }
                    }
                    DispatchQueue.main.async { result(outcome) }
                }
            case "routerUnload":
                if #available(iOS 18.0, *) { AskCakeRouterModel.shared.unload() }
                result(nil)
            case "benchStart":
                if #available(iOS 18.0, *) { result(AskCakeBench.shared.start()) } else { result(false) }
            case "benchStatus":
                if #available(iOS 18.0, *) { result(AskCakeBench.shared.snapshot()) } else { result(["running": false, "status": "needs iOS 18", "lines": []]) }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    #endif

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private static func makeSchema(_ spec: [String: Any]) throws -> GenerationSchema {
        let name = spec["name"] as? String ?? "Output"
        let properties = (spec["properties"] as? [[String: Any]] ?? []).map { property -> DynamicGenerationSchema.Property in
            let propertyName = property["name"] as? String ?? "value"
            let schema: DynamicGenerationSchema
            switch property["type"] as? String {
            case "int": schema = DynamicGenerationSchema(type: Int.self)
            case "bool": schema = DynamicGenerationSchema(type: Bool.self)
            case "enum":
                schema = DynamicGenerationSchema(name: "\(name)_\(propertyName)", anyOf: property["values"] as? [String] ?? [])
            default: schema = DynamicGenerationSchema(type: String.self)
            }
            return DynamicGenerationSchema.Property(
                name: propertyName,
                description: property["description"] as? String,
                schema: schema,
                isOptional: property["optional"] as? Bool ?? false)
        }
        return try GenerationSchema(root: DynamicGenerationSchema(name: name, properties: properties), dependencies: [])
    }

    @available(iOS 26.0, macOS 26.0, *)
    private static func map(_ error: Error) -> ModelError {
        // Framework error descriptions can echo prompt content; only pass a category on.
        let description = String(describing: error).lowercased()
        if description.contains("unsafe") || description.contains("sensitive") || description.contains("guardrail") || description.contains("refus") {
            return ModelError(code: "guardrail", message: "Blocked by the on-device model's content guardrails")
        }
        if description.contains("context") {
            return ModelError(code: "context", message: "Conversation too long for the model")
        }
        return ModelError(code: "generation", message: String(describing: type(of: error)))
    }
    #endif
}

#if canImport(CoreML)
import CoreML
#endif

/// Developer-only router benchmark. Reads models, pre-tokenised test inputs and a job list from
/// Documents/askcake_bench (copied there with devicectl), runs each job and writes one result file per job.
/// Scoring happens on the Mac from those files, so the phone only produces raw model outputs and timings.
@available(iOS 18.0, *)
final class AskCakeBench {
    static let shared = AskCakeBench()
    private let lock = NSLock()
    private var running = false
    private var status = "idle"
    private var lines: [String] = []

    private var dir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("askcake_bench")
    }

    func snapshot() -> [String: Any] {
        lock.lock(); defer { lock.unlock() }
        return ["running": running, "status": status, "lines": lines]
    }

    private func set(_ text: String) { lock.lock(); status = text; lock.unlock() }
    private func add(_ text: String) { lock.lock(); lines.append(text); lock.unlock() }

    func start() -> Bool {
        lock.lock()
        if running { lock.unlock(); return false }
        running = true; lines = []; status = "starting"
        lock.unlock()
        Task.detached(priority: .userInitiated) {
            await self.runAll()
            self.lock.lock(); self.running = false; self.status = "done"; self.lock.unlock()
        }
        return true
    }

    private static func memoryMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
        }
        return kr == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
    }

    private static func deviceName() -> String {
        var sys = utsname(); uname(&sys)
        let machine = withUnsafePointer(to: &sys.machine) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) } }
        return machine + " iOS " + ProcessInfo.processInfo.operatingSystemVersionString
    }

    private func json(_ name: String) -> [String: Any]? {
        guard let data = try? Data(contentsOf: dir.appendingPathComponent(name)) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private func runAll() async {
        guard let jobs = json("jobs.json")?["jobs"] as? [[String: Any]] else { add("no jobs.json in Documents/askcake_bench"); return }
        for job in jobs {
            let kind = job["kind"] as? String ?? ""
            let name = job["model"] as? String ?? kind
            let units = job["units"] as? String ?? "all"
            let label = (job["label"] as? String) ?? "\(name)-\(units)"
            let limit = job["limit"] as? Int ?? Int.max
            let sets = job["sets"] as? [String]
            set("\(label): loading")
            let baseline = Self.memoryMB()
            var out: [String: Any] = ["model": name, "kind": kind, "units": units, "device": Self.deviceName(), "baseline_mb": baseline]
            do {
                var results: [[String: Any]] = []
                var peak = baseline
                if kind == "afm" {
                    out["afm"] = AskCakeModel.shared.availability()
                    results = try await runAfm(label: label, limit: limit, sets: sets)
                    peak = max(peak, Self.memoryMB())
                } else {
                    #if canImport(CoreML)
                    guard let inputs = json("\(kind)_inputs.json"), var cases = inputs["cases"] as? [[String: Any]] else { throw AskCakeModel.ModelError(code: "inputs", message: "missing inputs") }
                    if let sets { cases = cases.filter { c in sets.contains { (c["k"] as? String ?? "").hasPrefix($0 + ":") } } }
                    let config = MLModelConfiguration()
                    switch units {
                    case "cpuOnly": config.computeUnits = .cpuOnly
                    case "cpuAndGPU": config.computeUnits = .cpuAndGPU
                    case "cpuAndNeuralEngine": config.computeUnits = .cpuAndNeuralEngine
                    default: config.computeUnits = .all
                    }
                    let t0 = Date()
                    let compiled = try await MLModel.compileModel(at: dir.appendingPathComponent("\(name).mlpackage"))
                    out["compile_ms"] = Int(Date().timeIntervalSince(t0) * 1000)
                    let t1 = Date()
                    let model = try MLModel(contentsOf: compiled, configuration: config)
                    out["load_ms"] = Int(Date().timeIntervalSince(t1) * 1000)
                    out["loaded_mb"] = Self.memoryMB()
                    let n = inputs["n"] as? Int ?? 128
                    let pad = Int32(inputs["pad"] as? Int ?? 0)
                    let stops = Set((inputs["stops"] as? [Int] ?? []).map { Int32($0) })
                    let maxNew = inputs["max_new"] as? Int ?? 80
                    let ids = try MLMultiArray(shape: [1, NSNumber(value: n)], dataType: .int32)
                    let att = try MLMultiArray(shape: [1, NSNumber(value: n)], dataType: .int32)
                    let pos = try MLMultiArray(shape: [1], dataType: .int32)
                    let idp = ids.dataPointer.bindMemory(to: Int32.self, capacity: n)
                    let atp = att.dataPointer.bindMemory(to: Int32.self, capacity: n)
                    for (index, c) in cases.prefix(limit).enumerated() {
                        let tokens = (c["ids"] as? [Int] ?? []).map { Int32($0) }
                        for i in 0..<n { idp[i] = i < tokens.count ? tokens[i] : pad; atp[i] = i < tokens.count ? 1 : 0 }
                        let started = Date()
                        var row: [String: Any] = ["k": c["k"] as? String ?? ""]
                        if kind == "enc" {
                            let o = try await model.prediction(from: MLDictionaryFeatureProvider(dictionary: ["ids": MLFeatureValue(multiArray: ids), "att": MLFeatureValue(multiArray: att)]))
                            let picks = o.featureValue(for: "picks")!.multiArrayValue!
                            let tags = o.featureValue(for: "tags")!.multiArrayValue!
                            row["picks"] = (0..<picks.count).map { picks[$0].intValue }
                            row["conf"] = o.featureValue(for: "conf")!.multiArrayValue![0].doubleValue
                            row["tags"] = (0..<min(tokens.count, tags.count)).map { tags[$0].intValue }
                        } else {
                            var length = tokens.count
                            var generated: [Int] = []
                            var passes = 0
                            while generated.count < maxNew && length < n {
                                pos[0] = NSNumber(value: Int32(length - 1))
                                let o = try await model.prediction(from: MLDictionaryFeatureProvider(dictionary: ["ids": MLFeatureValue(multiArray: ids), "pos": MLFeatureValue(multiArray: pos)]))
                                let next = o.featureValue(for: "next")!.multiArrayValue![0].int32Value
                                passes += 1
                                if stops.contains(next) { break }
                                generated.append(Int(next)); idp[length] = next; length += 1
                            }
                            row["gen"] = generated
                            row["passes"] = passes
                        }
                        row["ms"] = Date().timeIntervalSince(started) * 1000
                        results.append(row)
                        if index % 8 == 0 { peak = max(peak, Self.memoryMB()); set("\(label): \(index + 1)/\(min(limit, cases.count))") }
                    }
                    peak = max(peak, Self.memoryMB())
                    #endif
                }
                out["results"] = results
                out["memory_mb"] = peak - baseline
                out["peak_mb"] = peak
                out["thermal"] = ProcessInfo.processInfo.thermalState.rawValue
                let times = results.compactMap { $0["ms"] as? Double }.sorted()
                add("\(label): \(results.count) routes, median \(times.isEmpty ? 0 : Int(times[times.count / 2])) ms, +\(Int(peak - baseline)) MB")
            } catch {
                out["error"] = String(describing: error)
                add("\(label): FAILED \(String(describing: error).prefix(160))")
            }
            if let data = try? JSONSerialization.data(withJSONObject: out) {
                try? data.write(to: dir.appendingPathComponent("result-\(label).json"))
            }
        }
    }

    /// Apple's on-device model on the same cases: pick a capability from the fixed list, then fill its inputs.
    private func runAfm(label: String, limit: Int, sets: [String]?) async throws -> [[String: Any]] {
        guard let spec = json("afm_inputs.json"), var cases = spec["cases"] as? [[String: Any]] else { throw AskCakeModel.ModelError(code: "inputs", message: "missing afm_inputs.json") }
        if let sets { cases = cases.filter { c in sets.contains { (c["k"] as? String ?? "").hasPrefix($0 + ":") } } }
        let instructions = spec["instructions"] as? String ?? ""
        let choice = spec["choice"] as? [String: Any]
        let slotSchemas = spec["slots"] as? [String: [String: Any]] ?? [:]
        var results: [[String: Any]] = []
        for (index, c) in cases.prefix(limit).enumerated() {
            let started = Date()
            var row: [String: Any] = ["k": c["k"] as? String ?? ""]
            var label: [String: Any] = [:]
            do {
                let session = try AskCakeModel.shared.createSession(instructions: instructions)
                defer { AskCakeModel.shared.disposeSession(session) }
                var tool = ""
                for turn in c["turns"] as? [String] ?? [] {
                    let raw = try await AskCakeModel.shared.respond(sessionId: session, prompt: "User: \(turn)\nPick the capability.", schema: choice)
                    tool = ((try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any])?["tool"] as? String ?? ""
                }
                label["tool"] = tool
                if let schema = slotSchemas[tool], c["need_slots"] as? Bool == true {
                    let raw = try await AskCakeModel.shared.respond(sessionId: session, prompt: "Fill in the inputs from what the user wrote. Leave out anything they did not give.", schema: schema)
                    if let slots = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any] { for (k, v) in slots { label[k] = v } }
                }
            } catch let error as AskCakeModel.ModelError {
                row["error"] = error.code
            } catch {
                row["error"] = "generation"
            }
            row["label"] = label
            row["ms"] = Date().timeIntervalSince(started) * 1000
            results.append(row)
            if index % 4 == 0 { set("\(label): \(index + 1)/\(min(limit, cases.count))") }
        }
        return results
    }
}

/// The fine-tuned router model (SmolLM2-135M, Core ML). The model package is downloaded by the app on
/// first use (or copied into Documents/askcake_bench by a developer); it is compiled once and the
/// compiled copy is kept in Application Support.
/// The model has a fixed input length and no key-value cache: every new token is one full pass.
///
/// Loading for the Neural Engine takes several seconds on every launch, so the model is first loaded
/// for the CPU, which is quick, and used as is; the Neural Engine copy loads in the background and
/// takes over when it is ready.
@available(iOS 18.0, *)
final class AskCakeRouterModel {
    static let shared = AskCakeRouterModel()
    static let packageName = "smollm2-135m-p8"
    static let length = 192

    #if canImport(CoreML)
    private var model: MLModel?
    #endif
    private var generation = 0
    private var fastReady = false
    private let lock = NSLock()

    func unload() {
        #if canImport(CoreML)
        lock.lock(); model = nil; generation += 1; fastReady = false; lock.unlock()
        #endif
    }

    /// Whether the Neural Engine copy has taken over from the CPU copy.
    var isFast: Bool { lock.lock(); defer { lock.unlock() }; return fastReady }

    func load(path: String?) async -> [String: Any] {
        #if canImport(CoreML)
        lock.lock(); let existing = model; lock.unlock()
        if existing != nil { return ["loaded": true, "loadMs": 0, "cached": true] }
        let fm = FileManager.default
        let package = path.map { URL(fileURLWithPath: $0) } ?? fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("askcake_bench/\(Self.packageName).mlpackage")
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("askcake")
        let compiled = support.appendingPathComponent("\(Self.packageName).mlmodelc")
        let started = Date()
        var compiledNow = false
        do {
            // Recompile when the package's weights are newer than the cached
            // compiled model, so a replaced router is picked up.
            let weights = package.appendingPathComponent("Data/com.apple.CoreML/weights/weight.bin")
            let modified: (URL) -> Date? = { (try? fm.attributesOfItem(atPath: $0.path))?[.modificationDate] as? Date }
            if let source = modified(weights), let cache = modified(compiled), source > cache {
                try? fm.removeItem(at: compiled)
            }
            if !fm.fileExists(atPath: compiled.path) {
                guard fm.fileExists(atPath: package.path) else { return ["loaded": false, "reason": "modelMissing"] }
                let temporary = try await MLModel.compileModel(at: package)
                try fm.createDirectory(at: support, withIntermediateDirectories: true)
                try fm.moveItem(at: temporary, to: compiled)
                compiledNow = true
            }
            let quick = MLModelConfiguration()
            quick.computeUnits = .cpuOnly
            let loaded = try MLModel(contentsOf: compiled, configuration: quick)
            lock.lock(); model = loaded; generation += 1; let mine = generation; lock.unlock()
            Task.detached(priority: .utility) { [weak self] in
                let full = MLModelConfiguration()
                full.computeUnits = .all
                guard let fast = try? MLModel(contentsOf: compiled, configuration: full), let self else { return }
                self.lock.lock()
                if self.generation == mine { self.model = fast; self.fastReady = true }
                self.lock.unlock()
            }
            return ["loaded": true, "loadMs": Int(Date().timeIntervalSince(started) * 1000), "compiled": compiledNow]
        } catch {
            return ["loaded": false, "reason": "loadFailed", "detail": String(describing: error).prefix(200).description]
        }
        #else
        return ["loaded": false, "reason": "unsupportedPlatform"]
        #endif
    }

    /// The generated token ids and, when the model reports it, the probability it gave each one.
    func generate(ids: [Int], stops: Set<Int>, maxNew: Int) async throws -> [String: Any] {
        #if canImport(CoreML)
        lock.lock(); let loaded = model; lock.unlock()
        guard let loaded, !ids.isEmpty, ids.count < Self.length else { throw AskCakeModel.ModelError(code: "router", message: "not loaded or prompt too long") }
        let n = Self.length
        let input = try MLMultiArray(shape: [1, NSNumber(value: n)], dataType: .int32)
        let position = try MLMultiArray(shape: [1], dataType: .int32)
        let pointer = input.dataPointer.bindMemory(to: Int32.self, capacity: n)
        for i in 0..<n { pointer[i] = i < ids.count ? Int32(ids[i]) : 0 }
        var count = ids.count
        var generated: [Int] = []
        var confidence: [Double] = []
        while generated.count < maxNew && count < n {
            position[0] = NSNumber(value: Int32(count - 1))
            let output = try await loaded.prediction(from: MLDictionaryFeatureProvider(dictionary: [
                "ids": MLFeatureValue(multiArray: input), "pos": MLFeatureValue(multiArray: position),
            ]))
            let next = Int(output.featureValue(for: "next")!.multiArrayValue![0].int32Value)
            if stops.contains(next) { break }
            if let conf = output.featureValue(for: "conf")?.multiArrayValue { confidence.append(conf[0].doubleValue) }
            generated.append(next); pointer[count] = Int32(next); count += 1
        }
        return ["ids": generated, "conf": confidence, "fast": isFast]
        #else
        throw AskCakeModel.ModelError(code: "unavailable", message: "Core ML missing")
        #endif
    }
}

package main

import (
	"C"
	"unsafe"

	"github.com/ltcmweb/mwebd"
)

var server *mwebd.Server

//export StartServer
func StartServer(chain *C.char, dataDir *C.char, nodeUri *C.char, errMsg **C.char) C.int {
	if server != nil {
		server.Stop()
	}
	goChain := C.GoString(chain)
	goDataDir := C.GoString(dataDir)
	goNodeUri := C.GoString(nodeUri)

	var err error
	server, err = mwebd.NewServer(goChain, goDataDir, goNodeUri)
	if err != nil {
		*errMsg = C.CString(err.Error())
		return 0
	}

	err = server.StartUnix(goDataDir + "/mwebd.sock")
	if err != nil {
		*errMsg = C.CString(err.Error())
		return 0
	}

	return 1
}

//export StopServer
func StopServer() {
	if server == nil {
		return
	}
	server.Stop()
	server = nil
}

//export Addresses
func Addresses(scanSecret *C.char, scanSecretLen C.int, spendPubKey *C.char, spendPubKeyLen C.int, i C.int, j C.int) *C.char {
	// Convert C pointers to Go byte slices
	goScanSecret := C.GoBytes(unsafe.Pointer(scanSecret), scanSecretLen)
	goSpendPubKey := C.GoBytes(unsafe.Pointer(spendPubKey), spendPubKeyLen)

	// Call the original Go function
	addr := mwebd.Addresses(goScanSecret, goSpendPubKey, int32(i), int32(j))

	// Convert the resulting Go string to a C string
	// The C code must free this memory
	return C.CString(addr)
}

func main() {}

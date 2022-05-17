# Read me for CW_LDK #

This document is for explaining what is CW_LDK plug is, how it was implemented, and where does it need more work in.

The lightning network is a second layer solution for handling bitcoin transaction off chain.
[Here](https://www.youtube.com/watch?v=dZBiod8fe1M&t=239s) is an excellent simple presentation by Hannah Rosenburg on how it works. 

One of the challenges of creating a custodial Lightning wallet is that if by any chance you close out a channel by posting an outdated commitment transaction, you could be penalized and lose all your funds that you had setup in that channel.  So it crucial that the lightning node is always running in the background to receive the latest commitment transaction and revocation secrets.

After much research it was decided to go with a framework called the LDK (Lightning Development Kit: https://lightningdevkit.org/) which was just released this December and is funded by Jack Dorsey.  The only other option for implementing a lightning custodian wallet is writing one from scratch. 

The LDK is developed in a system programming language called Rust but also it has bindings in Swift, Java, and C now.    We decided to go with the Rust version so that we could just write the code that setup and run the LDK once and have it interface with flutter through the FFI (Foreign Function Interface).

We took a sample project that was written in rust called the [ldk-sample](https://github.com/lightningdevkit/ldk-sample) project .  It was a basic lightning wallet written for the command line.  We just modified it to that it could interface with flutter through the FFI.  We also modified it so that instead of receiving input through a command prompt, messages would be passed using [thread channels](https://www.youtube.com/watch?v=FE1BkKqYCGU), which is a message passing service that rust provides for threads to communicate with each other.  I would like to reiterate that the LDK must always be running and the code that setup and runs the LDK executes on a separate background thread.  Thread Channels is how to you have separate threads communicate with each other in rust.

The Rust code that works with the LDK is located under cw_ldk/native.  Inside you will find two rust projects ldk-lib and ldk-ffi.  The ldk-lib is the code that works with the ldk.  The ldk-ffi is where we make ffi interfaces to communicate with flutter.  The ldk-ffi references the ldk-lib as a seperate libary.

Inside ldk-ffi, you will notice a file named libldk_ffi.h.  This is a c header file that is created each time you compile ldk-ffi.  For Android, you don't need to bother with this.  But for iOS you need to include this.   So If you change any of the interfaces in ldk-ffi, you need to go to under cw_ldk/ios/Classes/libldk_ffi.h, and insert the new interface function, between the section commented  //// begin insert,  and ///// end insert

The ldk-lib libary is basically the ldk-sample project with some modifications.  You will notice some duplicated code between lib.rs and main.rs.  and between cli.rs and flutter_ffi.rs.  This is because you still run the comand prompt version if you want for testing a debuging reasons.  

To be able to compile for Android or iOS, it important to follow the instuctions outlined in howto-build-cw_ldk.md.  once that is done you will notice that there is a make file located in cw_ldk/Makefile, where you can execute comands for compiling your rust code for Android and iOS and copying the ouput to the approriate folders.  

To compile for only Android just type 
```
make android
```
To compile for iOS type
```
make ios
```
To build for all type
```
make build
```
again it's important to remind you if you change the ldk-ffi interface in any way you need to copy and past those changes to ios/Classes/libldk_ffi.h

there is a file located at cw_ldk/lib/ffi.dart, which gets generated automatically each time we compile ldk-ffi.  each function defined in ldk-ffi gets a function in dart to call it.
the cw_ldk/lib/cw_ldk.dart file is just another layer on top of ffi.dart for a flutter app to call.

inside cw_ldk there is a an example project to show you how to use the cw_ldk in your application.


## setup polar.

In order to run the example project for cw_ldk, you need a local regtest setup on your development machine.  I would sugest using a tool that runs on top of docker called polar.
here is a youtube clip show how to use and set on up.  https://www.youtube.com/watch?v=XvEjZs3fifk.  Once you have a regtest network running on your machine you should be good to go.

## what got done.

The interfacing of rust to flutter is pretty much done.  However we have only gotten compiling rust for Android to work for Android 18.***.  We have not figured out how to get rust to compile for the newer NDKs.

So one of the challenges for compiling for the ffi is that flutter can not print to the debugging console using the print! macro.  if you want to print to the console you have to pass in a function pointer to a function you wrote in flutter that prints to the console.
another challenge is that you can only print to the debugging console if you you are running on the main thread.  But since the LDK must run in a background thread it can be hard to figure out what is happening if something crashes.

The way we figure around this was to use isolates which is flutter way of handling parallel execution.  even though the ldk is running as a background process it can now print to the debugging console show something if an exception was thrown.  That was not the case when we first attempted to run it as a rust thread.  Something would crash and we would not know what happened unless we consulted the error logs.

the function CwLdk.startLDK which starts the LDK in a background thread works.  
the function CwLdk.nodeInfo works, which shows the information of your node.


## what is left to do.

every function that is left to be implemented is mark with Todo: in the comments, in cw_ldk/lib/cw_ldk.dart

Where we got stuck is the connectToPeer method. 

it is throwing the following exception when we attempt to connect to a peer in a regtest network that I setup with polar. 

```
I/flutter (18501): Request to ldk: connectpeer 03efcf3a659de7ca716cea0044617549c5bc82dd71f7d43363d6bceeb7321b34a6@192.168.0.12:9735
F/libc    (18501): Fatal signal 6 (SIGABRT), code -6 in tid 18569 (DartWorker), pid 18501 (.cw_ldk_example)
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
Build fingerprint: 'motorola/potter_amxla_n/potter_n:8.1.0/OPS28.85-17-6-2/77e7:user/release-keys'
Revision: 'p3b0'
ABI: 'arm'
pid: 18501, tid: 18569, name: DartWorker  >>> com.cakewallet.cw_ldk_example <<<
signal 6 (SIGABRT), code -6 (SI_TKILL), fault addr --------
    r0 00000000  r1 00004889  r2 00000006  r3 00000008
    r4 00004845  r5 00004889  r6 7f6df61c  r7 0000010c
    r8 00000000  r9 7f6df720  sl 8da2a600  fp 841a9b9c
    ip 00000000  sp 7f6df608  lr accc292d  pc accbc41a  cpsr 200b0030
backtrace:
    #00 pc 0001a41a  /system/lib/libc.so (abort+63)
    #01 pc 00620b59  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (std::sys::unix::abort_internal::h27567bb454ff1f0f+2)
    #02 pc 0061e0f9  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (rust_panic+104)
    #03 pc 0061df19  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (std::panicking::rust_panic_with_hook::hb04cf113abc0a279+576)
    #04 pc 0061dcab  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (std::panicking::begin_panic_handler::_$u7b$$u7b$closure$u7d$$u7d$::h948087b056ae599a+90)
    #05 pc 0061c41f  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (std::sys_common::backtrace::__rust_end_short_backtrace::he1a6f233ff680ab5+10)
    #06 pc 0061dae9  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (rust_begin_unwind+36)
    #07 pc 00017c7f  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (core::panicking::panic_fmt::h0a7fa9be44dc7b9b+22)
    #08 pc 006324a1  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (core::panicking::panic_display::h4284bac35c7a025b+40)
    #09 pc 00632471  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (core::panicking::panic_str::hfbd9db0dbbe58477+12)
    #10 pc 00017bef  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (core::option::expect_failed::hb46680dd7fc32a66+2)
    #11 pc 005cf355  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (core::option::Option$LT$T$GT$::expect::h6de64f6757c8b5ca+44)
    #12 pc 005d437d  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::time::driver::handle::Handle::current::h081a16bc45eeb6bd+32)
    #13 pc 005c4cc1  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::time::driver::sleep::Sleep::new_timeout::h70209d5b9a7232c9+30)
    #14 pc 0004a0fd  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::time::timeout::timeout::h192c76cb1dae7c1b+158)
    #15 pc 001e5fdd  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (lightning_net_tokio::connect_outbound::_$u7b$$u7b$closure$u7d$$u7d$::h24a2d4303e65cc63+312)
    #16 pc 0004b5d1  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (_$LT$core..future..from_generator..GenFuture$LT$T$GT$$u20$as$u20$core..future..future..Future$GT$::poll::h1d5d837834018d55+60)
    #17 pc 001103a3  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (ldk_lib::cli::do_connect_peer::_$u7b$$u7b$closure$u7d$$u7d$::hb9b72d71646f2523+390)
    #18 pc 0004d109  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (_$LT$core..future..from_generator..GenFuture$LT$T$GT$$u20$as$u20$core..future..future..Future$GT$::poll::hf73024720f8355a9+50)
    #19 pc 0011014f  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (ldk_lib::cli::connect_peer_if_necessary::_$u7b$$u7b$closure$u7d$$u7d$::h24084115c6f2c1b2+578)
    #20 pc 0004ce8d  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (_$LT$core..future..from_generator..GenFuture$LT$T$GT$$u20$as$u20$core..future..future..Future$GT$::poll::he97c557c74a1eca8+50)
    #21 pc 000dd9df  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (ldk_lib::start_ldk::_$u7b$$u7b$closure$u7d$$u7d$::h245dab6855624ba0+26590)
    #22 pc 0004b159  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (_$LT$core..future..from_generator..GenFuture$LT$T$GT$$u20$as$u20$core..future..future..Future$GT$::poll::h0beb79a11bf81b3b+50)
    #23 pc 000188ed  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (ldk_ffi::start_ldk::_$u7b$$u7b$closure$u7d$$u7d$::h2148884bdcb210af+1376)
    #24 pc 0004bb23  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (_$LT$core..future..from_generator..GenFuture$LT$T$GT$$u20$as$u20$core..future..future..Future$GT$::poll::h3fd2f38dcb216009+50)
    #25 pc 0001c5db  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::park::thread::CachedParkThread::block_on::_$u7b$$u7b$closure$u7d$$u7d$::h88eb418be047ff0a+30)
    #26 pc 002787ab  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::coop::with_budget::_$u7b$$u7b$closure$u7d$$u7d$::h27c4391d8fcb5790+126)
    #27 pc 002b574f  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (std::thread::local::LocalKey$LT$T$GT$::try_with::h707b78d02de5f72e+118)
    #28 pc 002b53d7  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (std::thread::local::LocalKey$LT$T$GT$::with::hdba8288b033b18dc+22)
    #29 pc 0001c2b7  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::park::thread::CachedParkThread::block_on::h5c596d9ccda9fb04+394)
    #30 pc 0031bd69  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::runtime::enter::Enter::block_on::h8bfbbea1b93c3be9+64)
    #31 pc 002d0c5d  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::runtime::thread_pool::ThreadPool::block_on::h3400a2cbeab3b90b+64)
    #32 pc 003224d5  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (tokio::runtime::Runtime::block_on::h4398d52635a94ef2+202)
    #33 pc 00018341  /data/app/com.cakewallet.cw_ldk_example-hte9uHg-xNObTQaNR3nQbA==/lib/arm/libldk_ffi.so (start_ldk+320)
    #34 pc 00004700  <anonymous:8ee00000>
Lost connection to device.
Exited (sigterm)
```

The weird thing is that this does not happen when I run the ldk-sample for the command prompt.  So I wonder if the is a firewall issue.

Once this is figured out.  The rest of the functions should fall into place.  since all you have to do is copy the code for the cli interface.










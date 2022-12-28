
#ifndef CW_MONERO_EXPORT_H
#define CW_MONERO_EXPORT_H

#ifdef CW_MONERO_STATIC_DEFINE
#  define CW_MONERO_EXPORT
#  define CW_MONERO_NO_EXPORT
#else
#  ifndef CW_MONERO_EXPORT
#    ifdef cw_monero_EXPORTS
        /* We are building this library */
#      define CW_MONERO_EXPORT __declspec(dllexport)
#    else
        /* We are using this library */
#      define CW_MONERO_EXPORT __declspec(dllimport)
#    endif
#  endif

#  ifndef CW_MONERO_NO_EXPORT
#    define CW_MONERO_NO_EXPORT 
#  endif
#endif

#ifndef CW_MONERO_DEPRECATED
#  define CW_MONERO_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef CW_MONERO_DEPRECATED_EXPORT
#  define CW_MONERO_DEPRECATED_EXPORT CW_MONERO_EXPORT CW_MONERO_DEPRECATED
#endif

#ifndef CW_MONERO_DEPRECATED_NO_EXPORT
#  define CW_MONERO_DEPRECATED_NO_EXPORT CW_MONERO_NO_EXPORT CW_MONERO_DEPRECATED
#endif

#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef CW_MONERO_NO_DEPRECATED
#    define CW_MONERO_NO_DEPRECATED
#  endif
#endif

#endif /* CW_MONERO_EXPORT_H */

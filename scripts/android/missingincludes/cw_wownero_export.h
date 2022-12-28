
#ifndef CW_WOWNERO_EXPORT_H
#define CW_WOWNERO_EXPORT_H

#ifdef CW_WOWNERO_STATIC_DEFINE
#  define CW_WOWNERO_EXPORT
#  define CW_WOWNERO_NO_EXPORT
#else
#  ifndef CW_WOWNERO_EXPORT
#    ifdef cw_wownero_EXPORTS
        /* We are building this library */
#      define CW_WOWNERO_EXPORT __declspec(dllexport)
#    else
        /* We are using this library */
#      define CW_WOWNERO_EXPORT __declspec(dllimport)
#    endif
#  endif

#  ifndef CW_WOWNERO_NO_EXPORT
#    define CW_WOWNERO_NO_EXPORT 
#  endif
#endif

#ifndef CW_WOWNERO_DEPRECATED
#  define CW_WOWNERO_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef CW_WOWNERO_DEPRECATED_EXPORT
#  define CW_WOWNERO_DEPRECATED_EXPORT CW_WOWNERO_EXPORT CW_WOWNERO_DEPRECATED
#endif

#ifndef CW_WOWNERO_DEPRECATED_NO_EXPORT
#  define CW_WOWNERO_DEPRECATED_NO_EXPORT CW_WOWNERO_NO_EXPORT CW_WOWNERO_DEPRECATED
#endif

#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef CW_WOWNERO_NO_DEPRECATED
#    define CW_WOWNERO_NO_DEPRECATED
#  endif
#endif

#endif /* CW_WOWNERO_EXPORT_H */

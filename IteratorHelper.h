#ifndef __IteratorHelper_h__
#define __IteratorHelper_h__

// code Ruby for awhile and C++ iterators start to look crude and disgusting
#define iterate_each( iterator_type, iterator_name, container )  \
        for ( iterator_type iterator_name = container.begin(); iterator_name != container.end(); ++iterator_name )

#define iterate_times( x ) \
        for ( unsigned int i__LINE__ = 0; i__LINE__ < (x); ++i__LINE__ )

#endif // __IteratorHelper_h__

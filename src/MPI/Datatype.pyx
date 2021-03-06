# Storage order for arrays
# ------------------------

ORDER_C       = MPI_ORDER_C       #: C order (a.k.a. row major)
ORDER_FORTRAN = MPI_ORDER_FORTRAN #: Fortran order (a.k.a. column major)
ORDER_F       = MPI_ORDER_FORTRAN #: Convenience alias for ORDER_FORTRAN


# Type classes for Fortran datatype matching
# ------------------------------------------
TYPECLASS_INTEGER = MPI_TYPECLASS_INTEGER
TYPECLASS_REAL    = MPI_TYPECLASS_REAL
TYPECLASS_COMPLEX = MPI_TYPECLASS_COMPLEX


# Type of distributions (HPF-like arrays)
# ---------------------------------------

DISTRIBUTE_NONE      = MPI_DISTRIBUTE_NONE      #: Dimension not distributed
DISTRIBUTE_BLOCK     = MPI_DISTRIBUTE_BLOCK     #: Block distribution
DISTRIBUTE_CYCLIC    = MPI_DISTRIBUTE_CYCLIC    #: Cyclic distribution
DISTRIBUTE_DFLT_DARG = MPI_DISTRIBUTE_DFLT_DARG #: Default distribution


# Combiner values for datatype decoding
# -------------------------------------
COMBINER_NAMED            = MPI_COMBINER_NAMED
COMBINER_DUP              = MPI_COMBINER_DUP
COMBINER_CONTIGUOUS       = MPI_COMBINER_CONTIGUOUS
COMBINER_VECTOR           = MPI_COMBINER_VECTOR
COMBINER_HVECTOR          = MPI_COMBINER_HVECTOR
COMBINER_HVECTOR_INTEGER  = MPI_COMBINER_HVECTOR_INTEGER  #: from Fortran call
COMBINER_INDEXED          = MPI_COMBINER_INDEXED
COMBINER_HINDEXED_INTEGER = MPI_COMBINER_HINDEXED_INTEGER #: from Fortran call
COMBINER_HINDEXED         = MPI_COMBINER_HINDEXED
COMBINER_INDEXED_BLOCK    = MPI_COMBINER_INDEXED_BLOCK
COMBINER_HINDEXED_BLOCK   = MPI_COMBINER_HINDEXED_BLOCK
COMBINER_STRUCT           = MPI_COMBINER_STRUCT
COMBINER_STRUCT_INTEGER   = MPI_COMBINER_STRUCT_INTEGER   #: from Fortran call
COMBINER_SUBARRAY         = MPI_COMBINER_SUBARRAY
COMBINER_DARRAY           = MPI_COMBINER_DARRAY
COMBINER_RESIZED          = MPI_COMBINER_RESIZED
COMBINER_F90_REAL         = MPI_COMBINER_F90_REAL
COMBINER_F90_COMPLEX      = MPI_COMBINER_F90_COMPLEX
COMBINER_F90_INTEGER      = MPI_COMBINER_F90_INTEGER


cdef class Datatype:

    """
    Datatype
    """

    def __cinit__(self, Datatype datatype=None):
        self.ob_mpi = MPI_DATATYPE_NULL
        if datatype is not None:
            self.ob_mpi = datatype.ob_mpi

    def __dealloc__(self):
        if not (self.flags & PyMPI_OWNED): return
        CHKERR( del_Datatype(&self.ob_mpi) )

    def __richcmp__(self, other, int op):
        if not isinstance(self,  Datatype): return NotImplemented
        if not isinstance(other, Datatype): return NotImplemented
        cdef Datatype s = <Datatype>self, o = <Datatype>other
        if   op == Py_EQ: return (s.ob_mpi == o.ob_mpi)
        elif op == Py_NE: return (s.ob_mpi != o.ob_mpi)
        else: raise TypeError("only '==' and '!='")

    def __bool__(self):
        return self.ob_mpi != MPI_DATATYPE_NULL

    # Datatype Accessors
    # ------------------

    def Get_size(self):
        """
        Return the number of bytes occupied
        by entries in the datatype
        """
        cdef MPI_Count size = 0
        CHKERR( MPI_Type_size_x(self.ob_mpi, &size) )
        return size

    property size:
        """size (in bytes)"""
        def __get__(self):
            cdef MPI_Count size = 0
            CHKERR( MPI_Type_size_x(self.ob_mpi, &size) )
            return size

    def Get_extent(self):
        """
        Return lower bound and extent of datatype
        """
        cdef MPI_Count lb = 0, extent = 0
        CHKERR( MPI_Type_get_extent_x(self.ob_mpi, &lb, &extent) )
        return (lb, extent)

    property extent:
        """extent"""
        def __get__(self):
            cdef MPI_Count lb = 0, extent = 0
            CHKERR( MPI_Type_get_extent_x(self.ob_mpi, &lb, &extent) )
            return extent

    property lb:
        """lower bound"""
        def __get__(self):
            cdef MPI_Count lb = 0, extent = 0
            CHKERR( MPI_Type_get_extent_x(self.ob_mpi, &lb, &extent) )
            return lb

    property ub:
        """upper bound"""
        def __get__(self):
            cdef MPI_Count lb = 0, extent = 0
            CHKERR( MPI_Type_get_extent_x(self.ob_mpi, &lb, &extent) )
            return lb + extent

    # Datatype Constructors
    # ---------------------

    def Dup(self):
        """
        Duplicate a datatype
        """
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_dup(self.ob_mpi, &datatype.ob_mpi) )
        return datatype

    Create_dup = Dup #: convenience alias

    def Create_contiguous(self, int count):
        """
        Create a contiguous datatype
        """
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_contiguous(count, self.ob_mpi,
                                    &datatype.ob_mpi) )
        return datatype

    def Create_vector(self, int count, int blocklength, int stride):
        """
        Create a vector (strided) datatype
        """
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_vector(count, blocklength, stride,
                                self.ob_mpi, &datatype.ob_mpi) )
        return datatype

    def Create_hvector(self, int count, int blocklength, Aint stride):
        """
        Create a vector (strided) datatype
        """
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_create_hvector(count, blocklength, stride,
                                        self.ob_mpi,
                                        &datatype.ob_mpi) )
        return datatype

    def Create_indexed(self, blocklengths, displacements):
        """
        Create an indexed datatype
        """
        cdef int count = 0, *iblen = NULL, *idisp = NULL
        blocklengths  = getarray_int(blocklengths,  &count, &iblen)
        displacements = chkarray_int(displacements,  count, &idisp)
        #
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_indexed(count, iblen, idisp,
                                 self.ob_mpi, &datatype.ob_mpi) )
        return datatype

    def Create_hindexed(self, blocklengths, displacements):
        """
        Create an indexed datatype
        with displacements in bytes
        """
        cdef int count = 0, *iblen = NULL
        blocklengths = getarray_int(blocklengths, &count, &iblen)
        cdef MPI_Aint *idisp = NULL
        displacements = asarray_Aint(displacements, count, &idisp)
        #
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_create_hindexed(count, iblen, idisp,
                                         self.ob_mpi,
                                         &datatype.ob_mpi) )
        return datatype

    def Create_indexed_block(self, int blocklength, displacements):
        """
        Create an indexed datatype
        with constant-sized blocks
        """
        cdef int count = 0, *idisp = NULL
        displacements = getarray_int(displacements, &count, &idisp)
        #
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_create_indexed_block(count, blocklength,
                                              idisp, self.ob_mpi,
                                              &datatype.ob_mpi) )
        return datatype

    def Create_hindexed_block(self, int blocklength, displacements):
        """
        Create an indexed datatype
        with constant-sized blocks
        and displacements in bytes
        """
        cdef int count = 0
        cdef MPI_Aint *idisp = NULL
        count = <int>len(displacements) # XXX Overflow ?
        displacements = asarray_Aint(displacements, count, &idisp)
        #
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_create_hindexed_block(count, blocklength,
                                               idisp, self.ob_mpi,
                                               &datatype.ob_mpi) )
        return datatype

    @classmethod
    def Create_struct(cls, blocklengths, displacements, datatypes):
        """
        Create an datatype from a general set of
        block sizes, displacements and datatypes
        """
        cdef int count = 0, *iblen = NULL
        blocklengths = getarray_int(blocklengths, &count, &iblen)
        cdef MPI_Aint *idisp = NULL
        displacements = asarray_Aint(displacements, count, &idisp)
        cdef MPI_Datatype *ptype = NULL
        datatypes = asarray_Datatype(datatypes, count, &ptype)
        #
        cdef Datatype datatype = <Datatype>cls()
        CHKERR( MPI_Type_create_struct(count, iblen, idisp, ptype,
                                       &datatype.ob_mpi) )
        return datatype

    # Subarray Datatype Constructor
    # -----------------------------

    def Create_subarray(self, sizes, subsizes, starts,
                        int order=ORDER_C):
        """
        Create a datatype for a subarray of
        a regular, multidimensional array
        """
        cdef int ndims = 0, *isizes = NULL
        cdef int *isubsizes = NULL, *istarts = NULL
        sizes    = getarray_int(sizes,   &ndims, &isizes   )
        subsizes = chkarray_int(subsizes, ndims, &isubsizes)
        starts   = chkarray_int(starts,   ndims, &istarts  )
        cdef int iorder = MPI_ORDER_C
        if order is not None: iorder = order
        #
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_create_subarray(ndims, isizes,
                                         isubsizes, istarts,
                                         iorder, self.ob_mpi,
                                         &datatype.ob_mpi) )
        return datatype

    # Distributed Array Datatype Constructor
    # --------------------------------------

    def Create_darray(self, int size, int rank,
                      gsizes, distribs, dargs, psizes,
                      int order=ORDER_C):
        """
        Create a datatype representing an HPF-like
        distributed array on Cartesian process grids
        """
        cdef int ndims = 0, *igsizes = NULL
        cdef int *idistribs = NULL, *idargs = NULL, *ipsizes = NULL
        gsizes   = getarray_int(gsizes,  &ndims, &igsizes   )
        distribs = chkarray_int(distribs, ndims, &idistribs )
        dargs    = chkarray_int(dargs,    ndims, &idargs    )
        psizes   = chkarray_int(psizes,   ndims, &ipsizes   )
        #
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_create_darray(size, rank, ndims, igsizes,
                                       idistribs, idargs, ipsizes,
                                       order, self.ob_mpi,
                                       &datatype.ob_mpi) )
        return datatype

    # Parametrized and size-specific Fortran Datatypes
    # ------------------------------------------------

    @classmethod
    def Create_f90_integer(cls, int r):
        """
        Return a bounded integer datatype
        """
        cdef Datatype datatype = <Datatype>cls()
        CHKERR( MPI_Type_create_f90_integer(r, &datatype.ob_mpi) )
        return datatype

    @classmethod
    def Create_f90_real(cls, int p, int r):
        """
        Return a bounded real datatype
        """
        cdef Datatype datatype = <Datatype>cls()
        CHKERR( MPI_Type_create_f90_real(p, r, &datatype.ob_mpi) )
        return datatype

    @classmethod
    def Create_f90_complex(cls, int p, int r):
        """
        Return a bounded complex datatype
        """
        cdef Datatype datatype = <Datatype>cls()
        CHKERR( MPI_Type_create_f90_complex(p, r, &datatype.ob_mpi) )
        return datatype

    @classmethod
    def Match_size(cls, int typeclass, int size):
        """
        Find a datatype matching a specified size in bytes
        """
        cdef Datatype datatype = <Datatype>cls()
        CHKERR( MPI_Type_match_size(typeclass, size, &datatype.ob_mpi) )
        return datatype

    # Use of Derived Datatypes
    # ------------------------

    def Commit(self):
        """
        Commit the datatype
        """
        CHKERR( MPI_Type_commit(&self.ob_mpi) )
        return self

    def Free(self):
        """
        Free the datatype
        """
        CHKERR( MPI_Type_free(&self.ob_mpi) )

    # Datatype Resizing
    # -----------------

    def Create_resized(self, Aint lb, Aint extent):
        """
        Create a datatype with a new lower bound and extent
        """
        cdef Datatype datatype = <Datatype>type(self)()
        CHKERR( MPI_Type_create_resized(self.ob_mpi,
                                        lb, extent,
                                        &datatype.ob_mpi) )
        return datatype

    Resized = Create_resized #: compatibility alias

    def Get_true_extent(self):
        """
        Return the true lower bound and extent of a datatype
        """
        cdef MPI_Count lb = 0, extent = 0
        CHKERR( MPI_Type_get_true_extent_x(self.ob_mpi,
                                           &lb, &extent) )
        return (lb, extent)

    property true_extent:
        """true extent"""
        def __get__(self):
            cdef MPI_Count lb = 0, extent = 0
            CHKERR( MPI_Type_get_true_extent_x(self.ob_mpi,
                                               &lb, &extent) )
            return extent

    property true_lb:
        """true lower bound"""
        def __get__(self):
            cdef MPI_Count lb = 0, extent = 0
            CHKERR( MPI_Type_get_true_extent_x(self.ob_mpi,
                                               &lb, &extent) )
            return lb

    property true_ub:
        """true upper bound"""
        def __get__(self):
            cdef MPI_Count lb = 0, extent = 0
            CHKERR( MPI_Type_get_true_extent_x(self.ob_mpi,
                                               &lb, &extent) )
            return lb + extent

    # Decoding a Datatype
    # -------------------

    def Get_envelope(self):
        """
        Return information on the number and type of input arguments
        used in the call that created a datatype
        """
        cdef int ni = 0, na = 0, nd = 0, combiner = MPI_UNDEFINED
        CHKERR( MPI_Type_get_envelope(self.ob_mpi, &ni, &na, &nd, &combiner) )
        return (ni, na, nd, combiner)

    def Get_contents(self):
        """
        Retrieve the actual arguments used in the call that created a
        datatype
        """
        cdef int ni = 0, na = 0, nd = 0, combiner = MPI_UNDEFINED
        CHKERR( MPI_Type_get_envelope(self.ob_mpi, &ni, &na, &nd, &combiner) )
        cdef int *i = NULL
        cdef MPI_Aint *a = NULL
        cdef MPI_Datatype *d = NULL
        cdef tmp1 = allocate(ni, sizeof(int), <void**>&i)
        cdef tmp2 = allocate(na, sizeof(MPI_Aint), <void**>&a)
        cdef tmp3 = allocate(nd, sizeof(MPI_Datatype), <void**>&d)
        CHKERR( MPI_Type_get_contents(self.ob_mpi, ni, na, nd, i, a, d) )
        cdef int k = 0
        cdef object integers  = [i[k] for k from 0 <= k < ni]
        cdef object addresses = [a[k] for k from 0 <= k < na]
        cdef object datatypes = [new_Datatype(d[k]) for k from 0 <= k < nd]
        return (integers, addresses, datatypes)

    def decode(self):
        """
        Convenience method for decoding a datatype
        """
        # get the datatype envelope
        cdef int ni = 0, na = 0, nd = 0, combiner = MPI_UNDEFINED
        CHKERR( MPI_Type_get_envelope(self.ob_mpi, &ni, &na, &nd, &combiner) )
        # return self immediately for named datatypes
        if combiner == MPI_COMBINER_NAMED: return self
        # get the datatype contents
        cdef int *i = NULL
        cdef MPI_Aint *a = NULL
        cdef MPI_Datatype *d = NULL
        cdef tmp1 = allocate(ni, sizeof(int), <void**>&i)
        cdef tmp2 = allocate(na, sizeof(MPI_Aint), <void**>&a)
        cdef tmp3 = allocate(nd, sizeof(MPI_Datatype), <void**>&d)
        CHKERR( MPI_Type_get_contents(self.ob_mpi, ni, na, nd, i, a, d) )
        # manage in advance the contained datatypes
        cdef int k = 0, s1, e1, s2, e2, s3, e3, s4, e4
        cdef object oldtype = None
        if (combiner == <int>MPI_COMBINER_STRUCT or
            combiner == <int>MPI_COMBINER_STRUCT_INTEGER):
            oldtype = [new_Datatype(d[k]) for k from 0 <= k < nd]
        elif (combiner != <int>MPI_COMBINER_F90_INTEGER and
              combiner != <int>MPI_COMBINER_F90_REAL and
              combiner != <int>MPI_COMBINER_F90_COMPLEX):
            oldtype = new_Datatype(d[0])
        # dispatch depending on the combiner value
        if combiner == <int>MPI_COMBINER_DUP:
            return (oldtype, ('DUP'), {})
        elif combiner == <int>MPI_COMBINER_CONTIGUOUS:
            return (oldtype, ('CONTIGUOUS'),
                    {('count') : i[0]})
        elif combiner == <int>MPI_COMBINER_VECTOR:
            return (oldtype, ('VECTOR'),
                    {('count')       : i[0],
                     ('blocklength') : i[1],
                     ('stride')      : i[2]})
        elif (combiner == <int>MPI_COMBINER_HVECTOR or
              combiner == <int>MPI_COMBINER_HVECTOR_INTEGER):
            return (oldtype, ('HVECTOR'),
                    {('count')       : i[0],
                     ('blocklength') : i[1],
                     ('stride')      : a[0]})
        elif combiner == <int>MPI_COMBINER_INDEXED:
            s1 =      1; e1 =   i[0]
            s2 = i[0]+1; e2 = 2*i[0]
            return (oldtype, ('INDEXED'),
                    {('blocklengths')  : [i[k] for k from s1 <= k <= e1],
                     ('displacements') : [i[k] for k from s2 <= k <= e2]})
        elif (combiner == <int>MPI_COMBINER_HINDEXED or
              combiner == <int>MPI_COMBINER_HINDEXED_INTEGER):
            s1 = 1; e1 = i[0]
            s2 = 0; e2 = i[0]-1
            return (oldtype, ('HINDEXED'),
                    {('blocklengths')  : [i[k] for k from s1 <= k <= e1],
                     ('displacements') : [a[k] for k from s2 <= k <= e2]})
        elif combiner == <int>MPI_COMBINER_INDEXED_BLOCK:
            s2 = 2; e2 = i[0]+1
            return (oldtype, ('INDEXED_BLOCK'),
                    {('blocklength')   : i[1],
                     ('displacements') : [i[k] for k from s2 <= k <= e2]})
        elif combiner == <int>MPI_COMBINER_HINDEXED_BLOCK:
            s2 = 0; e2 = i[0]-1
            return (oldtype, ('HINDEXED_BLOCK'),
                    {('blocklength')   : i[1],
                     ('displacements') : [a[k] for k from s2 <= k <= e2]})
        elif (combiner == <int>MPI_COMBINER_STRUCT or
              combiner == <int>MPI_COMBINER_STRUCT_INTEGER):
            s1 = 1; e1 = i[0]
            s2 = 0; e2 = i[0]-1
            return (Datatype, ('STRUCT'),
                    {('blocklengths')  : [i[k] for k from s1 <= k <= e1],
                     ('displacements') : [a[k] for k from s2 <= k <= e2],
                     ('datatypes')     : oldtype})
        elif combiner == <int>MPI_COMBINER_SUBARRAY:
            s1 =        1; e1 =   i[0]
            s2 =   i[0]+1; e2 = 2*i[0]
            s3 = 2*i[0]+1; e3 = 3*i[0]
            return (oldtype, ('SUBARRAY'),
                    {('sizes')    : [i[k] for k from s1 <= k <= e1],
                     ('subsizes') : [i[k] for k from s2 <= k <= e2],
                     ('starts')   : [i[k] for k from s3 <= k <= e3],
                     ('order')    : i[3*i[0]+1]})
        elif combiner == <int>MPI_COMBINER_DARRAY:
            s1 =        3; e1 =   i[2]+2
            s2 =   i[2]+3; e2 = 2*i[2]+2
            s3 = 2*i[2]+3; e3 = 3*i[2]+2
            s4 = 3*i[2]+3; e4 = 4*i[2]+2
            return (oldtype, ('DARRAY'),
                    {('size')     : i[0],
                     ('rank')     : i[1],
                     ('gsizes')   : [i[k] for k from s1 <= k <= e1],
                     ('distribs') : [i[k] for k from s2 <= k <= e2],
                     ('dargs')    : [i[k] for k from s3 <= k <= e3],
                     ('psizes')   : [i[k] for k from s4 <= k <= e4],
                     ('order')    : i[4*i[2]+3]})
        elif combiner == <int>MPI_COMBINER_RESIZED:
            return (oldtype, ('RESIZED'),
                    {('lb')     : a[0],
                     ('extent') : a[1]})
        elif combiner == <int>MPI_COMBINER_F90_INTEGER:
            return (Datatype, ('F90_INTEGER'),
                    {('r') : i[0]})
        elif combiner == <int>MPI_COMBINER_F90_REAL:
            return (Datatype, ('F90_REAL'),
                    {('p') : i[0],
                     ('r') : i[1]})
        elif combiner == <int>MPI_COMBINER_F90_COMPLEX:
            return (Datatype, ('F90_COMPLEX'),
                    {('p') : i[0],
                     ('r') : i[1]})


    # Pack and Unpack
    # ---------------

    def Pack(self, inbuf, outbuf, int position, Comm comm not None):
        """
        Pack into contiguous memory according to datatype.
        """
        cdef MPI_Aint lb = 0, extent = 0
        CHKERR( MPI_Type_get_extent(self.ob_mpi, &lb, &extent) )
        #
        cdef void *ibptr = NULL, *obptr = NULL
        cdef MPI_Aint iblen = 0, oblen = 0
        cdef ob1 = getbuffer_r(inbuf,  &ibptr, &iblen)
        cdef ob2 = getbuffer_w(outbuf, &obptr, &oblen)
        cdef int icount = <int>(iblen/extent), osize = <int>oblen
        #
        CHKERR( MPI_Pack(ibptr, icount, self.ob_mpi, obptr, osize,
                         &position, comm.ob_mpi) )
        return position

    def Unpack(self, inbuf, int position, outbuf, Comm comm not None):
        """
        Unpack from contiguous memory according to datatype.
        """
        cdef MPI_Aint lb = 0, extent = 0
        CHKERR( MPI_Type_get_extent(self.ob_mpi, &lb, &extent) )
        #
        cdef void *ibptr = NULL, *obptr = NULL
        cdef MPI_Aint iblen = 0, oblen = 0
        cdef ob1 = getbuffer_r(inbuf,  &ibptr, &iblen)
        cdef ob2 = getbuffer_w(outbuf, &obptr, &oblen)
        cdef int isize = <int>iblen, ocount = <int>(oblen/extent)
        #
        CHKERR( MPI_Unpack(ibptr, isize, &position, obptr, ocount,
                           self.ob_mpi, comm.ob_mpi) )
        return position

    def Pack_size(self, int count, Comm comm not None):
        """
        Returns the upper bound on the amount of space (in bytes)
        needed to pack a message according to datatype.
        """
        cdef int size = 0
        CHKERR( MPI_Pack_size(count, self.ob_mpi,
                              comm.ob_mpi, &size) )
        return size

    # Canonical Pack and Unpack
    # -------------------------

    def Pack_external(self, datarep, inbuf, outbuf, Aint position):
        """
        Pack into contiguous memory according to datatype,
        using a portable data representation (**external32**).
        """
        cdef char *cdatarep = NULL
        datarep = asmpistr(datarep, &cdatarep, NULL)
        cdef MPI_Aint lb = 0, extent = 0
        CHKERR( MPI_Type_get_extent(self.ob_mpi, &lb, &extent) )
        #
        cdef void *ibptr = NULL, *obptr = NULL
        cdef MPI_Aint iblen = 0, oblen = 0
        cdef ob1 = getbuffer_r(inbuf,  &ibptr, &iblen)
        cdef ob2 = getbuffer_w(outbuf, &obptr, &oblen)
        cdef int icount = <int>(iblen/extent) # XXX overflow?
        cdef MPI_Aint osize = oblen
        #
        CHKERR( MPI_Pack_external(cdatarep, ibptr, icount,
                                  self.ob_mpi,
                                  obptr, osize, &position) )
        return position

    def Unpack_external(self, datarep, inbuf, Aint position, outbuf):
        """
        Unpack from contiguous memory according to datatype,
        using a portable data representation (**external32**).
        """
        cdef char *cdatarep = NULL
        datarep = asmpistr(datarep, &cdatarep, NULL)
        cdef MPI_Aint lb = 0, extent = 0
        CHKERR( MPI_Type_get_extent(self.ob_mpi, &lb, &extent) )
        #
        cdef void *ibptr = NULL, *obptr = NULL
        cdef MPI_Aint iblen = 0, oblen = 0
        cdef ob1 = getbuffer_r(inbuf,  &ibptr, &iblen)
        cdef ob2 = getbuffer_w(outbuf, &obptr, &oblen)
        cdef MPI_Aint isize = iblen,
        cdef int ocount = <int>(oblen/extent) # XXX overflow?
        #
        CHKERR( MPI_Unpack_external(cdatarep, ibptr, isize, &position,
                                    obptr, ocount, self.ob_mpi) )
        return position

    def Pack_external_size(self, datarep, int count):
        """
        Returns the upper bound on the amount of space (in bytes)
        needed to pack a message according to datatype,
        using a portable data representation (**external32**).
        """
        cdef char *cdatarep = NULL
        cdef MPI_Aint size = 0
        datarep = asmpistr(datarep, &cdatarep, NULL)
        CHKERR( MPI_Pack_external_size(cdatarep, count,
                                       self.ob_mpi, &size) )
        return size

    # Attributes
    # ----------

    def Get_attr(self, int keyval):
        """
        Retrieve attribute value by key
        """
        cdef void *attrval = NULL
        cdef int flag = 0
        CHKERR( MPI_Type_get_attr(self.ob_mpi, keyval, &attrval, &flag) )
        if not flag: return None
        if not attrval: return 0
        # handle predefined keyvals
        if 0: pass
        # likely be a user-defined keyval
        elif keyval in type_keyval:
            return <object>attrval
        else:
            return PyLong_FromVoidPtr(attrval)

    def Set_attr(self, int keyval, object attrval):
        """
        Store attribute value associated with a key
        """
        cdef void *ptrval = NULL
        cdef int incref = 0
        if keyval in type_keyval:
            ptrval = <void*>attrval
            incref = 1
        else:
            ptrval = PyLong_AsVoidPtr(attrval)
            incref = 0
        CHKERR(MPI_Type_set_attr(self.ob_mpi, keyval, ptrval) )
        if incref: Py_INCREF(attrval)

    def Delete_attr(self, int keyval):
        """
        Delete attribute value associated with a key
        """
        CHKERR(MPI_Type_delete_attr(self.ob_mpi, keyval) )

    @classmethod
    def Create_keyval(cls, copy_fn=None, delete_fn=None):
        """
        Create a new attribute key for datatypes
        """
        cdef int keyval = MPI_KEYVAL_INVALID
        cdef MPI_Type_copy_attr_function *_copy = type_attr_copy_fn
        cdef MPI_Type_delete_attr_function *_del = type_attr_delete_fn
        cdef void *extra_state = NULL
        CHKERR( MPI_Type_create_keyval(_copy, _del, &keyval, extra_state) )
        type_keyval_new(keyval, copy_fn, delete_fn)
        return keyval

    @classmethod
    def Free_keyval(cls, int keyval):
        """
        Free and attribute key for datatypes
        """
        cdef int keyval_save = keyval
        CHKERR( MPI_Type_free_keyval (&keyval) )
        type_keyval_del(keyval_save)
        return keyval

    # Naming Objects
    # --------------

    def Get_name(self):
        """
        Get the print name for this datatype
        """
        cdef char name[MPI_MAX_OBJECT_NAME+1]
        cdef int nlen = 0
        CHKERR( MPI_Type_get_name(self.ob_mpi, name, &nlen) )
        return tompistr(name, nlen)

    def Set_name(self, name):
        """
        Set the print name for this datatype
        """
        cdef char *cname = NULL
        name = asmpistr(name, &cname, NULL)
        CHKERR( MPI_Type_set_name(self.ob_mpi, cname) )

    property name:
        """datatype name"""
        def __get__(self):
            return self.Get_name()
        def __set__(self, value):
            self.Set_name(value)

    # Fortran Handle
    # --------------

    def py2f(self):
        """
        """
        return MPI_Type_c2f(self.ob_mpi)

    @classmethod
    def f2py(cls, arg):
        """
        """
        cdef Datatype datatype = <Datatype>cls()
        datatype.ob_mpi = MPI_Type_f2c(arg)
        return datatype



# Address Function
# ----------------

def Get_address(location):
    """
    Get the address of a location in memory
    """
    cdef void *baseptr = NULL
    cdef tmp = getbuffer_r(location, &baseptr, NULL)
    cdef MPI_Aint address = 0
    CHKERR( MPI_Get_address(baseptr, &address) )
    return address



cdef Datatype __DATATYPE_NULL__ = new_Datatype( MPI_DATATYPE_NULL )

cdef Datatype __UB__ = new_Datatype( MPI_UB )
cdef Datatype __LB__ = new_Datatype( MPI_LB )

cdef Datatype __PACKED__ = new_Datatype( MPI_PACKED )
cdef Datatype __BYTE__   = new_Datatype( MPI_BYTE   )
cdef Datatype __AINT__   = new_Datatype( MPI_AINT   )
cdef Datatype __OFFSET__ = new_Datatype( MPI_OFFSET )
cdef Datatype __COUNT__  = new_Datatype( MPI_COUNT  )

cdef Datatype __CHAR__               = new_Datatype( MPI_CHAR               )
cdef Datatype __WCHAR__              = new_Datatype( MPI_WCHAR              )
cdef Datatype __SIGNED_CHAR__        = new_Datatype( MPI_SIGNED_CHAR        )
cdef Datatype __SHORT__              = new_Datatype( MPI_SHORT              )
cdef Datatype __INT__                = new_Datatype( MPI_INT                )
cdef Datatype __LONG__               = new_Datatype( MPI_LONG               )
cdef Datatype __LONG_LONG__          = new_Datatype( MPI_LONG_LONG          )
cdef Datatype __UNSIGNED_CHAR__      = new_Datatype( MPI_UNSIGNED_CHAR      )
cdef Datatype __UNSIGNED_SHORT__     = new_Datatype( MPI_UNSIGNED_SHORT     )
cdef Datatype __UNSIGNED__           = new_Datatype( MPI_UNSIGNED           )
cdef Datatype __UNSIGNED_LONG__      = new_Datatype( MPI_UNSIGNED_LONG      )
cdef Datatype __UNSIGNED_LONG_LONG__ = new_Datatype( MPI_UNSIGNED_LONG_LONG )
cdef Datatype __FLOAT__              = new_Datatype( MPI_FLOAT              )
cdef Datatype __DOUBLE__             = new_Datatype( MPI_DOUBLE             )
cdef Datatype __LONG_DOUBLE__        = new_Datatype( MPI_LONG_DOUBLE        )

cdef Datatype __C_BOOL__                = new_Datatype( MPI_C_BOOL           )
cdef Datatype __INT8_T__                = new_Datatype( MPI_INT8_T           )
cdef Datatype __INT16_T__               = new_Datatype( MPI_INT16_T          )
cdef Datatype __INT32_T__               = new_Datatype( MPI_INT32_T          )
cdef Datatype __INT64_T__               = new_Datatype( MPI_INT64_T          )
cdef Datatype __UINT8_T__               = new_Datatype( MPI_UINT8_T          )
cdef Datatype __UINT16_T__              = new_Datatype( MPI_UINT16_T         )
cdef Datatype __UINT32_T__              = new_Datatype( MPI_UINT32_T         )
cdef Datatype __UINT64_T__              = new_Datatype( MPI_UINT64_T         )
cdef Datatype __C_COMPLEX__             = new_Datatype( MPI_C_COMPLEX        )
cdef Datatype __C_FLOAT_COMPLEX__       = new_Datatype( MPI_C_FLOAT_COMPLEX  )
cdef Datatype __C_DOUBLE_COMPLEX__      = new_Datatype( MPI_C_DOUBLE_COMPLEX )
cdef Datatype __C_LONG_DOUBLE_COMPLEX__ = new_Datatype(
                                              MPI_C_LONG_DOUBLE_COMPLEX      )

cdef Datatype __SHORT_INT__        = new_Datatype( MPI_SHORT_INT       )
cdef Datatype __TWOINT__           = new_Datatype( MPI_2INT            )
cdef Datatype __LONG_INT__         = new_Datatype( MPI_LONG_INT        )
cdef Datatype __FLOAT_INT__        = new_Datatype( MPI_FLOAT_INT       )
cdef Datatype __DOUBLE_INT__       = new_Datatype( MPI_DOUBLE_INT      )
cdef Datatype __LONG_DOUBLE_INT__  = new_Datatype( MPI_LONG_DOUBLE_INT )

cdef Datatype __CHARACTER__        = new_Datatype( MPI_CHARACTER        )
cdef Datatype __LOGICAL__          = new_Datatype( MPI_LOGICAL          )
cdef Datatype __INTEGER__          = new_Datatype( MPI_INTEGER          )
cdef Datatype __REAL__             = new_Datatype( MPI_REAL             )
cdef Datatype __DOUBLE_PRECISION__ = new_Datatype( MPI_DOUBLE_PRECISION )
cdef Datatype __COMPLEX__          = new_Datatype( MPI_COMPLEX          )
cdef Datatype __DOUBLE_COMPLEX__   = new_Datatype( MPI_DOUBLE_COMPLEX   )

cdef Datatype __LOGICAL1__  = new_Datatype( MPI_LOGICAL1  )
cdef Datatype __LOGICAL2__  = new_Datatype( MPI_LOGICAL2  )
cdef Datatype __LOGICAL4__  = new_Datatype( MPI_LOGICAL4  )
cdef Datatype __LOGICAL8__  = new_Datatype( MPI_LOGICAL8  )
cdef Datatype __INTEGER1__  = new_Datatype( MPI_INTEGER1  )
cdef Datatype __INTEGER2__  = new_Datatype( MPI_INTEGER2  )
cdef Datatype __INTEGER4__  = new_Datatype( MPI_INTEGER4  )
cdef Datatype __INTEGER8__  = new_Datatype( MPI_INTEGER8  )
cdef Datatype __INTEGER16__ = new_Datatype( MPI_INTEGER16 )
cdef Datatype __REAL2__     = new_Datatype( MPI_REAL2     )
cdef Datatype __REAL4__     = new_Datatype( MPI_REAL4     )
cdef Datatype __REAL8__     = new_Datatype( MPI_REAL8     )
cdef Datatype __REAL16__    = new_Datatype( MPI_REAL16    )
cdef Datatype __COMPLEX4__  = new_Datatype( MPI_COMPLEX4  )
cdef Datatype __COMPLEX8__  = new_Datatype( MPI_COMPLEX8  )
cdef Datatype __COMPLEX16__ = new_Datatype( MPI_COMPLEX16 )
cdef Datatype __COMPLEX32__ = new_Datatype( MPI_COMPLEX32 )

include "typemap.pxi"


# Predefined datatype handles
# ---------------------------

DATATYPE_NULL = __DATATYPE_NULL__ #: Null datatype handle
# Deprecated datatypes (since MPI-2)
UB = __UB__ #: upper-bound marker
LB = __LB__ #: lower-bound marker
# MPI-specific datatypes
PACKED = __PACKED__
BYTE   = __BYTE__
AINT   = __AINT__
OFFSET = __OFFSET__
COUNT  = __COUNT__
# Elementary C datatypes
CHAR                = __CHAR__
WCHAR               = __WCHAR__
SIGNED_CHAR         = __SIGNED_CHAR__
SHORT               = __SHORT__
INT                 = __INT__
LONG                = __LONG__
LONG_LONG           = __LONG_LONG__
UNSIGNED_CHAR       = __UNSIGNED_CHAR__
UNSIGNED_SHORT      = __UNSIGNED_SHORT__
UNSIGNED            = __UNSIGNED__
UNSIGNED_LONG       = __UNSIGNED_LONG__
UNSIGNED_LONG_LONG  = __UNSIGNED_LONG_LONG__
FLOAT               = __FLOAT__
DOUBLE              = __DOUBLE__
LONG_DOUBLE         = __LONG_DOUBLE__
# C99 datatypes
C_BOOL                = __C_BOOL__
INT8_T                = __INT8_T__
INT16_T               = __INT16_T__
INT32_T               = __INT32_T__
INT64_T               = __INT64_T__
UINT8_T               = __UINT8_T__
UINT16_T              = __UINT16_T__
UINT32_T              = __UINT32_T__
UINT64_T              = __UINT64_T__
C_COMPLEX             = __C_COMPLEX__
C_FLOAT_COMPLEX       = __C_FLOAT_COMPLEX__
C_DOUBLE_COMPLEX      = __C_DOUBLE_COMPLEX__
C_LONG_DOUBLE_COMPLEX = __C_LONG_DOUBLE_COMPLEX__
# C Datatypes for reduction operations
SHORT_INT        = __SHORT_INT__
INT_INT = TWOINT = __TWOINT__
LONG_INT         = __LONG_INT__
FLOAT_INT        = __FLOAT_INT__
DOUBLE_INT       = __DOUBLE_INT__
LONG_DOUBLE_INT  = __LONG_DOUBLE_INT__
# Elementary Fortran datatypes
CHARACTER        = __CHARACTER__
LOGICAL          = __LOGICAL__
INTEGER          = __INTEGER__
REAL             = __REAL__
DOUBLE_PRECISION = __DOUBLE_PRECISION__
COMPLEX          = __COMPLEX__
DOUBLE_COMPLEX   = __DOUBLE_COMPLEX__
# Size-specific Fortran datatypes
LOGICAL1  = __LOGICAL1__
LOGICAL2  = __LOGICAL2__
LOGICAL4  = __LOGICAL4__
LOGICAL8  = __LOGICAL8__
INTEGER1  = __INTEGER1__
INTEGER2  = __INTEGER2__
INTEGER4  = __INTEGER4__
INTEGER8  = __INTEGER8__
INTEGER16 = __INTEGER16__
REAL2     = __REAL2__
REAL4     = __REAL4__
REAL8     = __REAL8__
REAL16    = __REAL16__
COMPLEX4  = __COMPLEX4__
COMPLEX8  = __COMPLEX8__
COMPLEX16 = __COMPLEX16__
COMPLEX32 = __COMPLEX32__


# Convenience aliases
UNSIGNED_INT          = __UNSIGNED__
SIGNED_SHORT          = __SHORT__
SIGNED_INT            = __INT__
SIGNED_LONG           = __LONG__
SIGNED_LONG_LONG      = __LONG_LONG__
BOOL                  = __C_BOOL__
SINT8_T               = __INT8_T__
SINT16_T              = __INT16_T__
SINT32_T              = __INT32_T__
SINT64_T              = __INT64_T__
F_BOOL                = __LOGICAL__
F_INT                 = __INTEGER__
F_FLOAT               = __REAL__
F_DOUBLE              = __DOUBLE_PRECISION__
F_COMPLEX             = __COMPLEX__
F_FLOAT_COMPLEX       = __COMPLEX__
F_DOUBLE_COMPLEX      = __DOUBLE_COMPLEX__

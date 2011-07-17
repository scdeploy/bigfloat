cimport cmpfr

# Make precision limits available to Python
MPFR_PREC_MIN = cmpfr.MPFR_PREC_MIN
MPFR_PREC_MAX = cmpfr.MPFR_PREC_MAX

# Make rounding mode values available to Python
MPFR_RNDN =  cmpfr.MPFR_RNDN
MPFR_RNDZ =  cmpfr.MPFR_RNDZ
MPFR_RNDU =  cmpfr.MPFR_RNDU
MPFR_RNDD =  cmpfr.MPFR_RNDD
MPFR_RNDA =  cmpfr.MPFR_RNDA
MPFR_RNDF =  cmpfr.MPFR_RNDF
MPFR_RNDNA =  cmpfr.MPFR_RNDNA


# Checks for valid parameter ranges
cdef check_rounding_mode(cmpfr.mpfr_rnd_t rnd):
    # MPFR_RNDF not implemented yet; MPFR_RNDNA should not be used.
    if not MPFR_RNDN <= rnd <= MPFR_RNDA:
        raise ValueError("invalid rounding mode {}".format(rnd))


cdef check_base(int b):
    if not 2 <= b <= 62:
        raise ValueError("base should be in the range 2 to 62 (inclusive)")


cdef check_get_str_n(size_t n):
    if not (n == 0 or 2 <= n):
        raise ValueError("n should be either 0 or at least 2")    


cdef check_precision(cmpfr.mpfr_prec_t precision):
    if not MPFR_PREC_MIN <= precision <= MPFR_PREC_MAX:
        raise ValueError(
            "precision should be between {} and {}".format(
                MPFR_PREC_MIN, MPFR_PREC_MAX
            )
        )


cdef class Mpfr:
    """ Mutable arbitrary-precision floating-point type. """
    cdef cmpfr.mpfr_t _value

    def __cinit__(self, precision):
        check_precision(precision)
        cmpfr.mpfr_init2(self._value, precision)

    def __dealloc__(self):
        if self._value._mpfr_d != NULL:
            cmpfr.mpfr_clear(self._value)


def mpfr_get_str(int b, size_t n, Mpfr op not None, cmpfr.mpfr_rnd_t rnd):
    """ Compute a base 'b' string representation for 'op'.

    'b' should be an integer between 2 and 62 (inclusive).

    'rnd' gives the rounding mode to use.

    Returns a pair (digits, exp) where:

        'digits' gives the string of digits
        exp is the exponent

    The exponent is normalized so that 0.<digits>E<exp> approximates 'op'.

    Note that the signature of this function does not match that of the
    underlying MPFR function call.

    """
    cdef cmpfr.mpfr_exp_t exp
    cdef bytes digits

    check_base(b)
    check_get_str_n(n)
    check_rounding_mode(rnd)
    c_digits = cmpfr.mpfr_get_str(NULL, &exp, b, n, op._value, rnd)
    if c_digits == NULL:
        raise RuntimeError("Error during string conversion.")

    # It's possible for the conversion from c_digits to digits to raise, so use
    # a try-finally block to ensure that c_digits always gets freed.
    try:
        digits = str(c_digits)
    finally:
        cmpfr.mpfr_free_str(c_digits)

    return digits, exp


def mpfr_const_pi(Mpfr rop not None, cmpfr.mpfr_rnd_t rnd):
    check_rounding_mode(rnd)
    return cmpfr.mpfr_const_pi(rop._value, rnd)

def mpfr_set(Mpfr rop not None, Mpfr op not None, cmpfr.mpfr_rnd_t rnd):
    check_rounding_mode(rnd)
    return cmpfr.mpfr_set(rop._value, op._value, rnd)

def mpfr_set_d(Mpfr rop not None, double op, cmpfr.mpfr_rnd_t rnd):
    check_rounding_mode(rnd)
    return cmpfr.mpfr_set_d(rop._value, op, rnd)

def mpfr_set_str(Mpfr rop not None, bytes s, int base, cmpfr.mpfr_rnd_t rnd):
    check_base(base)
    check_rounding_mode(rnd)
    return cmpfr.mpfr_set_str(rop._value, s, base, rnd)

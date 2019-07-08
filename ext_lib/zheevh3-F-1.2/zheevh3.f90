! 2017, S.A. Sato, Modified the format of the code
! ----------------------------------------------------------------------------
! Numerical diagonalization of 3x3 matrcies
! Copyright (C) 2006  Joachim Kopp
! ----------------------------------------------------------------------------
! This library is free software; you can redistribute it and/or
! modify it under the terms of the GNU Lesser General Public
! License as published by the Free Software Foundation; either
! version 2.1 of the License, or (at your option) any later version.
!
! This library is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
! Lesser General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public
! License along with this library; if not, write to the Free Software
! Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
! ----------------------------------------------------------------------------


! ----------------------------------------------------------------------------
      SUBROUTINE ZHEEVH3(A, Q, W)
! ----------------------------------------------------------------------------
! Calculates the eigenvalues and normalized eigenvectors of a hermitian 3x3
! matrix A using Cardano's method for the eigenvalues and an analytical
! method based on vector cross products for the eigenvectors. However,
! if conditions are such that a large error in the results is to be
! expected, the routine falls back to using the slower, but more
! accurate QL algorithm. Only the diagonal and upper triangular parts of A need
! to contain meaningful values. Access to A is read-only.
! ----------------------------------------------------------------------------
! Parameters:
!   A: The hermitian input matrix
!   Q: Storage buffer for eigenvectors
!   W: Storage buffer for eigenvalues
! ----------------------------------------------------------------------------
! Dependencies:
!   SQRABS(), ZHEEVC3(), ZHETRD3(), ZHEEVQ3()
! ----------------------------------------------------------------------------
! Version history:
!   v1.2 (12 Mar 2012): Removed unused label to avoid gfortran warning
!   v1.1: Simplified fallback condition --> speed-up
!   v1.0: First released version
! ----------------------------------------------------------------------------
!     .. Arguments ..
      COMPLEX(8)       A(3,3)
      COMPLEX(8)       Q(3,3)
      DOUBLE PRECISION W(3)

!     .. Parameters ..
      DOUBLE PRECISION EPS
      PARAMETER        ( EPS = 2.2204460492503131D-16 )

!     .. Local Variables ..
      DOUBLE PRECISION NORM
      DOUBLE PRECISION ERROR
      DOUBLE PRECISION T, U
      INTEGER          J

!     .. External Functions ..
      DOUBLE PRECISION SQRABS
      EXTERNAL         SQRABS, ZHEEVC3, ZHEEVQ3

!     Calculate eigenvalues
      CALL ZHEEVC3(A, W)

!     --- The rest of this subroutine can be omitted if only the eigenvalues are desired ---

!     Prepare calculation of eigenvectors
!      N1      = DREAL(A(1, 1))**2 + SQRABS(A(1, 2)) + SQRABS(A(1, 3))
!      N2      = SQRABS(A(1, 2)) + DREAL(A(2, 2))**2 + SQRABS(A(2, 3))
      T       = MAX(ABS(W(1)), ABS(W(2)), ABS(W(3)))
      U       = MAX(T, T**2)
      ERROR   = 256.0D0 * EPS * U**2
!      ERROR   = 256.0D0 * EPS * (N1 + U) * (N2 + U)
      Q(1, 2) = A(1, 2) * A(2, 3) - A(1, 3) * DREAL(A(2, 2))
      Q(2, 2) = A(1, 3) * DCONJG(A(1, 2)) - A(2, 3) * DREAL(A(1, 1))
      Q(3, 2) = SQRABS(A(1, 2))

!     Calculate first eigenvector by the formula
!       v[0] = conj( (A - lambda[0]).e1 x (A - lambda[0]).e2 )
      Q(1, 1) = Q(1, 2) + A(1, 3) * W(1)
      Q(2, 1) = Q(2, 2) + A(2, 3) * W(1)
      Q(3, 1) = (DREAL(A(1,1)) - W(1)) * (DREAL(A(2,2)) - W(1)) - Q(3,2)
      NORM    = SQRABS(Q(1, 1)) + SQRABS(Q(2, 1)) + SQRABS(Q(3, 1))

!     If vectors are nearly linearly dependent, or if there might have
!     been large cancellations in the calculation of A(I,I) - W(1), fall
!     back to QL algorithm
!     Note that this simultaneously ensures that multiple eigenvalues do
!     not cause problems: If W(1) = W(2), then A - W(1) * I has rank 1,
!     i.e. all columns of A - W(1) * I are linearly dependent.
      IF (NORM .LE. ERROR) THEN
        CALL ZHEEVQ3(A, Q, W)
        RETURN
!     This is the standard branch
      ELSE
        NORM = SQRT(1.0D0 / NORM)
        DO 20, J = 1, 3
          Q(J, 1) = Q(J, 1) * NORM
   20   CONTINUE
      END IF
 
!     Calculate second eigenvector by the formula
!       v[1] = conj( (A - lambda[1]).e1 x (A - lambda[1]).e2 )
      Q(1, 2) = Q(1, 2) + A(1, 3) * W(2)
      Q(2, 2) = Q(2, 2) + A(2, 3) * W(2)
      Q(3, 2) = (DREAL(A(1,1)) - W(2)) * (DREAL(A(2,2)) - W(2)) &
        - DREAL(Q(3, 2))
      NORM    = SQRABS(Q(1, 2)) + SQRABS(Q(2, 2)) + DREAL(Q(3, 2))**2
      IF (NORM .LE. ERROR) THEN
        CALL ZHEEVQ3(A, Q, W)
        RETURN
      ELSE
        NORM = SQRT(1.0D0 / NORM)
        DO 40, J = 1, 3 
          Q(J, 2) = Q(J, 2) * NORM
   40   CONTINUE
      END IF

!     Calculate third eigenvector according to
!       v[2] = conj(v[0] x v[1])
      Q(1, 3) = DCONJG( Q(2, 1) * Q(3, 2) - Q(3, 1) * Q(2, 2) )
      Q(2, 3) = DCONJG( Q(3, 1) * Q(1, 2) - Q(1, 1) * Q(3, 2) )
      Q(3, 3) = DCONJG( Q(1, 1) * Q(2, 2) - Q(2, 1) * Q(1, 2) )

      END SUBROUTINE
! End of subroutine ZHEEVH3


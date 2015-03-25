
SUBROUTINE metropolis_hastings(s, a, b, energy, plot_bin)
    implicit none

    real(8), intent(in) :: s, a, b
    real(8), intent(out) :: energy
    integer(8), intent(out) :: plot_bin(0:49,0:49)
    
    integer :: i, bi_x, bi_y, N
    real(8) :: r1(0:2), r2(0:2), r1n(0:2), r2n(0:2), t(0:2), temp(0:2)
    real(8) :: rnd(1:9)
    real(8) :: PI, p
    
    real(8) :: r1L, r1R, r2L, r2R, r12, r12n, p1L, p1R, p2L, p2R, p12
    real(8) :: r1Lu(0:2), r1Ru(0:2), r2Lu(0:2), r2Ru(0:2), r12u(0:2)
    
    ! useful constants
    t  = (/ s/2, 0d+0, 0d+0 /)
    PI = 4*atan(1d+0)
    
    ! initialize random value generator
    CALL init_rnd()
    
    ! randomly initialize r1 and r2
    ! with uniform distribution between -s and s
    CALL random_number(r1)
    CALL random_number(r2)
    r1 = 2*s*r1-s
    r2 = 2*s*r2-s    
    
    ! find equilibrium
    DO i=1,5000

        ! generate an array of random numbers for proposing update for r1 and r2
        CALL random_number(rnd)

        ! propose update for r1 and r2 according to a step with uniform 
        ! random angles (phi, theta) and normal distributed radial 
        ! step size (R) with standard deviation s/2
        r1n = r1 + (s/2)*sqrt(-2*log(rnd(1)))*cos(2*PI*rnd(2))* & 	! 1+R*
            (/  sin(PI*rnd(3))*cos(2*PI*rnd(4)), &                  ! (sin(theta)cos(phi),
                sin(PI*rnd(3))*sin(2*PI*rnd(4)), &                  !  sin(theta)sin(phi),
                cos(PI*rnd(3)) /)                                   !  cos(theta))

        r2n = r2 + (s/2)*sqrt(-2*log(rnd(5)))*cos(2*PI*rnd(6))* &
            (/  sin(PI*rnd(7))*cos(2*PI*rnd(8)), &
                sin(PI*rnd(7))*sin(2*PI*rnd(8)), &
                cos(PI*rnd(7)) /)

        ! calculate the fraction of the new wave function divided by the old
        ! one
        r12n = sum((r1n-r2n)**2)**0.5
        r12 = sum((r1-r2)**2)**0.5
        p = ((exp(-sum((r1n+t)**2)**0.5/a) + exp(-sum((r1n-t)**2)**0.5/a))/ &   ! factor due to electron 1
             (exp(-sum((r1+t)**2)**0.5/a)  + exp(-sum((r1-t)**2)**0.5/a)))* &
            ((exp(-sum((r2n+t)**2)**0.5/a) + exp(-sum((r2n-t)**2)**0.5/a))/ &   ! factor due to electron 2
             (exp(-sum((r2+t)**2)**0.5/a)  + exp(-sum((r2-t)**2)**0.5/a)))* &
             (exp(r12n/(2+2*b*r12n)) / exp(r12/(2+2*b*r12)))                    ! interaction factor
        

        ! update r1 and r2 according to metropolis hastings algorithm
        IF (p**2 > rnd(9)) THEN
            r1 = r1n
            r2 = r2n
        END IF
    END DO
    
    ! calculate the integral
    N = 10000000
    DO i=1,N

        ! generate an array of random numbers for proposing update for r1 and r2
        rnd = 0
        CALL random_number(rnd)

        ! propose update for r1 and r2 according to a step with uniform 
        ! random angles (phi, theta) and normal distributed radial 
        ! step size (R) with standard deviation s/2
        r1n = r1 + (s/2)*sqrt(-2*log(rnd(1)))*cos(2*PI*rnd(2))* & 	! 1+R*
            (/  sin(PI*rnd(3))*cos(2*PI*rnd(4)), &                  ! (sin(theta)cos(phi),
                sin(PI*rnd(3))*sin(2*PI*rnd(4)), &                  !  sin(theta)sin(phi),
                cos(PI*rnd(3)) /)                                   !  cos(theta))

        r2n = r2 + (s/2)*sqrt(-2*log(rnd(5)))*cos(2*PI*rnd(6))* &
            (/  sin(PI*rnd(7))*cos(2*PI*rnd(8)), &
                sin(PI*rnd(7))*sin(2*PI*rnd(8)), &
                cos(PI*rnd(7)) /)

        r1L = sum((r1+t)**2)**0.5
        r1R = sum((r1-t)**2)**0.5
        r2L = sum((r2+t)**2)**0.5
        r2R = sum((r2-t)**2)**0.5
        r12 = sum((r1-r2)**2)**0.5
        r1Lu = (r1+t)/sum((r1+t)**2)**0.5
        r1Ru = (r1-t)/sum((r1-t)**2)**0.5
        r2Lu = (r2+t)/sum((r2+t)**2)**0.5
        r2Ru = (r2-t)/sum((r2-t)**2)**0.5
        r12u = (r1-r2)/sum((r1-r2)**2)**0.5
        p1L = exp(-r1L/a)
        p1R = exp(-r1R/a)
        p2L = exp(-r2L/a)
        p2R = exp(-r2R/a)
        p12 = exp(r12/(2+2*b*r12))
        
        ! calculate the fraction of the new wave function divided by the old
        ! one
        r12n = sum((r1n-r2n)**2)**0.5
        p = ((exp(-sum((r1n+t)**2)**0.5/a) + exp(-sum((r1n-t)**2)**0.5/a))/ &   ! factor due to electron 1
            (p1L + p1R))* &
            ((exp(-sum((r2n+t)**2)**0.5/a) + exp(-sum((r2n-t)**2)**0.5/a))/ &   ! factor due to electron 2
            (p2L + p2R))* &
            (exp(r12n/(2+2*b*r12n)) / p12)                                      ! interaction factor
        
        ! calculate the local energy
        temp = (p1L*r1Lu+p1R*r1Ru)/(p1L+p1R) - (p2L*r2Lu+p2R*r2Ru)/(p2L+p2R)
        energy = energy - 1/(a**2) + (p1L/r1L + p1R/r1R)/(a*(p1L+p1R)) + &
            (p2L/r2L + p2R/r2R)/(a*(p2L+p2R)) & 
            - 1/r1L - 1/r1R - 1/r2L - 1/r2R + 1/r12 + &
            dot_product(temp, r12u/(2*a*(1-b*r12)**2)) &
            - ((4*b+1)*r12+4)/((4*(1+b*r12)**4)*r12)

        ! update r1 and r2 according to metropolis hastings algorithm
        IF (p**2 > rnd(9)) THEN
            r1 = r1n
            r2 = r2n
        END IF
        
        ! bin the values for plotting
        bi_x = int(50*(r2(0)+s)/(2*s))
        bi_y = int(50*(r2(1)+s)/(2*s))
        IF (((bi_x >=0 ) .and. (bi_x < 50)) .and. &
            ((bi_y >=0 ) .and. (bi_y < 50)) .and. &
             abs(r2(2)) < 2*s/25)  THEN
            plot_bin(bi_x,bi_y) = plot_bin(bi_x,bi_y) + 1
        END IF
    END DO
    energy = energy/N
    
END SUBROUTINE metropolis_hastings


!---subroutine for initializing the random value generator---!
SUBROUTINE init_rnd()
    implicit none
    integer, dimension(:), allocatable :: seed
    integer, dimension(8) :: dtVals
    integer :: seedSize

    ! get a seed from system time
    CALL date_and_time(VALUES=dtVals)

    ! get size needed for random_seed
    CALL random_seed(SIZE=seedSize)

    ! intialize random generator with seed
    allocate(seed(seedSize))
    CALL random_seed(PUT=dtVals((9-seedSize):8))

END SUBROUTINE init_rnd
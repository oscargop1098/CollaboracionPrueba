from mpi4py import MPI
from random import randint, seed
from sys import argv
import array as ar
import merge_sort

def main():
    seed((argv[1]))
    comm = MPI.COMM_WORLD
    rank = comm.rank
    if rank == 0:
        lo = int(argv[2])
        hi = int(argv[3])
        A_size = int(argv[4])
        filename = argv[5]
        assert lo < hi, f"lower limit {lo} greater than higher {hi}, expected lo < hi"
        assert A_size > 0,  f"number lower than 0 expected, got: {A_size}"
        # A = ar.array('i',[-1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12])
        A = ar.array('i', [randint(lo, hi) for r in range(0, A_size)])
    else:
        A = ar.array('i', [])
    size = len(A) if rank == 0 else 0
    size = comm.bcast(size)
    A_ = ar.array('i',[0]*(size//comm.size))
    comm.Scatter([A, MPI.INT], [A_, MPI.INT], root = 0)
    merge_sort.merge_sort(A_, 0, size//comm.size-1)
    comm.Gather([A_,MPI.INT], [A,MPI.INT])
    if rank == 0:
        merge_sort.merge(A, 0, (len(A)-1)//2, len(A)-1)
        with open(filename, 'w') as f:
            num_cnt = 0
            for number in A:
                f.write(str(number) + ' ')
                num_cnt += 1
                if num_cnt == 80:
                    f.write('\n')
                    num_cnt = 0

if __name__ == "__main__":
    main()
from mpi4py import MPI
import array, math

def main():
    comm = MPI.COMM_WORLD
    rank = comm.rank
    if rank == 0:
        A = array.array('i',range(16))
    else:
        A = array.array('i',[])
    A_ = array.array('i', [0])
    comm.Scatter([A,MPI.INT], [A_,MPI.INT])
    mask = 1
    i = 0
    while ((rank & (mask >> 1)) == 0) and (i < int(math.log(comm.size, 2))):
        partner_rank = rank ^ mask
        if (rank & mask) > 0:
            comm.Send([A_,MPI.INT], dest=partner_rank)
        else:
            B_ = array.array('i',[0]*(len(A_)))
            comm.Recv([B_, MPI.INT], source=partner_rank)
            for item in B_:
                A_.append(item)
        i += 1
        mask = mask << 1
    if rank == 0:
        print(A_)
            

if __name__ == "__main__":
    main()
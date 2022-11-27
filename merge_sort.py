from sys import argv
import array

def merge(A, low, mid, hi):
    end_1 = mid - low + 1
    end_2 = hi - mid
    # initializes temporal arrays
    L = array.array('i')
    R = array.array('i')
    for i in range(0, end_1):
        L.append(A[low+i])
    for j in range(0, end_2):
        R.append(A[mid+j+1])
    i = 0
    j = 0
    # merges cards until one stack of card is empty
    while (i < end_1) and (j < end_2):
        if L[i] <= R[j]:
            A[low+i+j] = L[i]
            i += 1
        else:
            A[low+i+j] = R[j]
            j += 1
    # stacks remaining cards
    k = low + i + j
    for i_ in range(i, end_1):
        A[k] = L[i_]
        k += 1
    for j_ in range(j, end_2):
        A[k] = R[j_]
        k += 1

def merge_sort(A, low, hi):
    if hi > low:
        mid = ((low + hi) // 2)
        merge_sort(A, low, mid)
        merge_sort(A, mid+1, hi)
        merge(A, low, mid, hi)
    return A

def main():
    A = array.array('i', [-1, -2, -3, 9, 11])
    print(A)
    merge_sort(A, 0, len(A)-1)
    print(A)

if __name__ == "__main__":
    main()
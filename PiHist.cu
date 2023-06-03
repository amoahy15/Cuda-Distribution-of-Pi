#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define BLOCK_SIZE 256

__global__ void hist_kernel(const char *digits, int len, int *counts);
int main(int argc, char **argv)
{
    if (argc != 3)
    {
        fprintf(stderr, "Usage: %s <filename> <num_digits>\n", argv[0]);
        exit(1);
    }

    char *filename = argv[1];
    int num_digits = atoi(argv[2]);
    if (num_digits <= 0)
    {
        fprintf(stderr, "Number of digits must be positive\n");
        exit(1);
    }

    FILE *fp = fopen(filename, "r");
    if (!fp)
    {
        fprintf(stderr, "Failed to open file %s\n", filename);
        exit(1);
    }

    char *digits = (char *)malloc(num_digits * sizeof(char));
    if (!digits)
    {
        fprintf(stderr, "Failed to allocate memory\n");
        exit(1);
    }
    int len = fread(digits, sizeof(char), num_digits, fp);
    if (len != num_digits)
    {
        fprintf(stderr, "Failed to read expected number of digits\n");
        exit(1);
    }

    int *counts = (int *)calloc(10, sizeof(int));
    if (!counts)
    {
        fprintf(stderr, "Failed to allocate memory\n");
        exit(1);
    }

    char *d_digits;
    int *d_counts;
    cudaMalloc((void **)&d_digits, num_digits * sizeof(char));
    cudaMalloc((void **)&d_counts, 10 * sizeof(int));
    cudaMemcpy(d_digits, digits, num_digits * sizeof(char), cudaMemcpyHostToDevice);
    cudaMemcpy(d_counts, counts, 10 * sizeof(int), cudaMemcpyHostToDevice);

    int num_blocks = (num_digits + BLOCK_SIZE - 1) / BLOCK_SIZE;
    hist_kernel<<<num_blocks, BLOCK_SIZE>>>(d_digits, num_digits, d_counts);

    cudaMemcpy(counts, d_counts, 10 * sizeof(int), cudaMemcpyDeviceToHost);
    printf("Digit counts: ");
    for (int i = 0; i < 10; i++)
    {
        printf("%d:%d ", i, counts[i]);
    }
    printf("\n");

    FILE *output_file = fopen("digit_counts.csv", "a");
    if (!output_file)
    {
        fprintf(stderr, "Failed to create output file\n");
        exit(1);
    }
    fprintf(output_file, "Number of digits: %d\n", num_digits);
    fprintf(output_file, "digit,frequency\n");
    for (int i = 0; i < 10; i++)
    {
        fprintf(output_file, "%d,%d\n", i, counts[i]);
    }
    fprintf(output_file, "\n");
    fclose(output_file);

    cudaFree(d_digits);
    cudaFree(d_counts);
    free(digits);
    free(counts);
    fclose(fp);

    return 0;
}
__global__ void hist_kernel(const char *digits, int len, int *counts)
{
    __shared__ int block_counts[10];
    for (int i = threadIdx.x; i < 10; i += blockDim.x)
    {
        block_counts[i] = 0;
    }
    __syncthreads();

    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    while (idx < len)
    {
        int digit = digits[idx] - '0';
        atomicAdd(&block_counts[digit], 1);
        idx += gridDim.x * blockDim.x;
    }
    __syncthreads();

    for (int i = threadIdx.x; i < 10; i += blockDim.x)
    {
        atomicAdd(&counts[i], block_counts[i]);
    }
}
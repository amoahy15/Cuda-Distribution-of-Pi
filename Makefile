all: 
	gcc  -o cHist  PiHist.c
	nvcc -o cuHist  PiHist.cu
run: all
	./cHist	pi-10million.txt 10
	./cuHist pi-10million.txt 10
	./cHist	pi-10million.txt 100
	./cuHist pi-10million.txt 100
	./cHist	pi-10million.txt 1000
	./cuHist pi-10million.txt 1000
	./cHist	pi-10million.txt 10000
	./cuHist pi-10million.txt 10000

	
clean:
	rm -f cHist
	rm -f cuHist
	rm -f digit_counts.csv

// Michał Matak - obracanie obrazka


#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>

#pragma pack(push, 1)
typedef struct
{
	uint16_t bfType; 
	uint32_t  bfSize; 
	uint16_t bfReserved1; 
	uint16_t bfReserved2; 
	uint32_t  bfOffBits; 
	uint32_t  biSize; 
	int32_t  biWidth; 
	int32_t  biHeight; 
	int16_t biPlanes; 
	int16_t biBitCount; 
	uint32_t  biCompression; 
	uint32_t  biSizeImage; 
	int32_t biXPelsPerMeter; 
	int32_t biYPelsPerMeter; 
	uint32_t  biClrUsed; 
	uint32_t  biClrImportant;
	uint32_t  RGBQuad_0;
	uint32_t  RGBQuad_1;
} bmpHdr;
#pragma pack(pop)

typedef struct
{
	int width, height, true_width, true_height;		// szerokosc i wysokosc obrazu
	unsigned char* pImg;	// wskazanie na początek danych pikselowych
	} imgInfo;

extern void rotate(unsigned char* pix_start, unsigned char* new_pic, int height, int width);

void* freeResources(FILE* pFile, void* pFirst, void* pSnd)
{
	if (pFile != 0)
		fclose(pFile);
	if (pFirst != 0)
		free(pFirst);
	if (pSnd !=0)
		free(pSnd);
	return 0;
}

imgInfo* readBMP(const char* fname)
{
	imgInfo* pInfo = 0;
	FILE* fbmp = 0;
	bmpHdr bmpHead;
	int lineBytes, y;
	unsigned long imageSize = 0;
	unsigned char* ptr;

	pInfo = (imgInfo *) malloc(sizeof(imgInfo));
	fbmp = fopen(fname, "rb");
	if (fbmp == 0)
		return 0;

	fread((void *) &bmpHead, sizeof(bmpHead), 1, fbmp);
	// some basic checks
	
	if (bmpHead.bfType != 0x4D42 || bmpHead.biPlanes != 1 ||
		bmpHead.biBitCount != 1 || (pInfo = (imgInfo *) malloc(sizeof(imgInfo))) == 0)
		{
		return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);
		}
	pInfo->true_width = bmpHead.biWidth;
	pInfo->true_height = bmpHead.biHeight;
	pInfo->width = (((bmpHead.biWidth + 31) >> 5) << 5);
	pInfo->height = (((bmpHead.biHeight + 31) >> 5) << 5);
	imageSize = ((pInfo->width)<<3) * pInfo->height;

	if ((pInfo->pImg = (unsigned char*) malloc(imageSize)) == 0)
		return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

	ptr = pInfo->pImg;
	lineBytes = (pInfo->width >> 2); // line size in bytes
	if (fseek(fbmp, bmpHead.bfOffBits, SEEK_SET) != 0)
		return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

	for (y=0; y<pInfo->height; ++y)
	{
		fread(ptr, 1, abs(lineBytes), fbmp);
		ptr += lineBytes;
	}
	fclose(fbmp);
	return pInfo;
}

int saveBMP(const imgInfo* pInfo, const char* fname)
{
	int lineBytes = ((pInfo->width + 31) >> 5)<<2;
	bmpHdr bmpHead = 
	{
	0x4D42,				// unsigned short bfType; 
	sizeof(bmpHdr),		// unsigned long  bfSize; 
	0, 0,				// unsigned short bfReserved1, bfReserved2; 
	sizeof(bmpHdr),		// unsigned long  bfOffBits; 
	40,					// unsigned long  biSize; 
	pInfo->width,		// long  biWidth; 
	pInfo->height,		// long  biHeight; 
	1,					// short biPlanes; 
	1,					// short biBitCount; 
	0,					// unsigned long  biCompression; 
	lineBytes * pInfo->height,	// unsigned long  biSizeImage; 
	11811,				// long biXPelsPerMeter; = 300 dpi
	11811,				// long biYPelsPerMeter; 
	2,					// unsigned long  biClrUsed; 
	0,					// unsigned long  biClrImportant;
	0x00000000,			// unsigned long  RGBQuad_0;
	0x00FFFFFF			// unsigned long  RGBQuad_1;
	};

	FILE * fbmp;
	unsigned char *ptr;
	int y;

	if ((fbmp = fopen(fname, "wb")) == 0)
		return -1;
	if (fwrite(&bmpHead, sizeof(bmpHdr), 1, fbmp) != 1)
	{
		fclose(fbmp);
		return -2;
	}

	ptr = pInfo->pImg;
	for (y=1; y <= pInfo->height; y++, ptr += lineBytes)
		if (fwrite(ptr, sizeof(unsigned char), lineBytes, fbmp) != lineBytes)
		{
			fclose(fbmp);
			return -3;
		}
	fclose(fbmp);
	return 0;
}

/****************************************************************************************/
void FreeRotatedScreen(imgInfo* pInfo)
{
	if (pInfo && pInfo->pImg)
		pInfo->pImg -= ((((pInfo->true_width + 31) >> 5) << 5) - pInfo->true_width)
						*(((pInfo->true_height + 31) >> 5) << 2);
		free(pInfo->pImg);
	if (pInfo)
		free(pInfo);
}

void rotation(imgInfo* pInfo)
{
	unsigned char* trg = malloc((pInfo->width * pInfo->height));
	unsigned char* src = pInfo->pImg;
	unsigned char* csrc = src;
	unsigned char* ctrg = trg;
	int higsize = ((pInfo->height)>>3);
	int rowsize = ((pInfo->width)>>3);
	int i, j;
	
	//algorytm obracania obrazka
	trg += (pInfo->width)*higsize;
	trg -= higsize;
	for (j=0; j<higsize; j++)
	{
		for (i=0; i<rowsize; i++)
		{
			rotate(src, trg, rowsize, higsize);
			src += 1;
			trg = trg - (8 * higsize);
		}
		trg += (pInfo->width)*(higsize)+1;
		src -= rowsize;
		src += 8*rowsize;
	}
	ctrg += (pInfo->width - pInfo->true_width)*higsize;
	// odpowiednie ustawienie atrybutów
	pInfo->height = pInfo->true_width;
	pInfo->width = pInfo->true_height;
	pInfo->pImg = ctrg;
	free(csrc);
}

void rotation_with_save(const char* input_name, const char* output_name)
{
	imgInfo* pInfo;
	pInfo = readBMP(input_name);
	rotation(pInfo);
	saveBMP(pInfo, output_name);
	FreeRotatedScreen(pInfo);
}

int main(int argc, char* argv[])
{
	rotation_with_save("utest.bmp", "result.bmp");
	return 0;
}


/* SPDX-License-Identifier: GPL-2.0-or-later
 * Reject incomplete/unsupported Apple/PWG Raster before system PS conversion. */
#include <cups/raster.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char **argv) {
    if (argc != 2) return 1;
    int fd = open(argv[1], O_RDONLY);
    if (fd < 0) return 1;
    cups_raster_t *r = cupsRasterOpen(fd, CUPS_RASTER_READ);
    if (!r) { close(fd); return 1; }
    cups_page_header2_t h;
    unsigned pages = 0;
    int status = 0;
    while (cupsRasterReadHeader2(r, &h)) {
        unsigned channels;
        switch (h.cupsColorSpace) {
            case CUPS_CSPACE_W: case CUPS_CSPACE_SW: case CUPS_CSPACE_K: channels=1; break;
            case CUPS_CSPACE_RGB: case CUPS_CSPACE_SRGB: channels=3; break;
            default: status=1; goto done;
        }
        if (!h.cupsWidth || h.cupsWidth > 6000 || !h.cupsHeight || h.cupsHeight > 10000 ||
            (h.cupsBitsPerColor != 1 && h.cupsBitsPerColor != 8) ||
            h.cupsBitsPerPixel != channels*h.cupsBitsPerColor || h.cupsNumColors != channels ||
            h.cupsColorOrder != CUPS_ORDER_CHUNKED ||
            !h.HWResolution[0] || !h.HWResolution[1] ||
            h.HWResolution[0] > 1200 || h.HWResolution[1] > 1200) { status=1; goto done; }
        unsigned minimum=(h.cupsWidth*h.cupsBitsPerPixel+7)/8;
        if (h.cupsBytesPerLine < minimum || h.cupsBytesPerLine > minimum+64) { status=1; goto done; }
        unsigned char *row=malloc(h.cupsBytesPerLine);
        if (!row) { status=1; goto done; }
        for (unsigned y=0; y<h.cupsHeight; y++) {
            if (cupsRasterReadPixels(r,row,h.cupsBytesPerLine) != h.cupsBytesPerLine) {
                free(row); status=1; goto done;
            }
        }
        free(row); pages++;
    }
    if (!pages) status=1;
done:
    cupsRasterClose(r); close(fd);
    if (status) fputs("ERROR: Incomplete or unsupported raster document.\n",stderr);
    return status;
}

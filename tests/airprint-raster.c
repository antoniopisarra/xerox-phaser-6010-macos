/* SPDX-License-Identifier: GPL-2.0-or-later
 * Synthetic Apple Raster fixture; no printer access. */
#include <cups/raster.h>
#include <string.h>
#include <unistd.h>
int main(void) {
  cups_page_header2_t h;
  memset(&h, 0, sizeof(h));
  h.HWResolution[0] = h.HWResolution[1] = 600;
  h.cupsWidth = h.cupsHeight = 64;
  h.cupsBitsPerColor = 8; h.cupsBitsPerPixel = 24;
  h.cupsBytesPerLine = 64 * 3; h.cupsNumColors = 3;
  h.cupsColorSpace = CUPS_CSPACE_SRGB;
  h.cupsColorOrder = CUPS_ORDER_CHUNKED;
  h.PageSize[0] = h.PageSize[1] = 8;
  h.cupsPageSize[0] = h.cupsPageSize[1] = 7.68f;
  h.NumCopies = 1;
  cups_raster_t *r = cupsRasterOpen(STDOUT_FILENO, CUPS_RASTER_WRITE_APPLE);
  if (!r || !cupsRasterWriteHeader2(r, &h)) return 1;
  unsigned char row[64 * 3];
  for (unsigned y=0; y<64; y++) {
    for (unsigned x=0; x<64; x++) {
      row[x*3] = x*4; row[x*3+1] = y*4; row[x*3+2] = 128;
    }
    if (cupsRasterWritePixels(r, row, sizeof(row)) != sizeof(row)) return 1;
  }
  cupsRasterClose(r);
  return 0;
}

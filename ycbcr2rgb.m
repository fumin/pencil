## Copyright (C) 2013 CarnĂŤ Draug <carandraug@octave.org>
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Function File} {@var{cmap} =} ycbcr2rgb (@var{YCbCrmap})
## @deftypefnx {Function File} {@var{RGB} =} ycbcr2rgb (@var{YCbCr})
## @deftypefnx {Function File} {@dots{} =} ycbcr2rgb (@dots{}, [@var{Kb} @var{Kr}])
## @deftypefnx {Function File} {@dots{} =} ycbcr2rgb (@dots{}, @var{standard})
## Convert YCbCr color space to RGB.
##
## The convertion changes the image @var{YCbCr} or colormap @var{YCbCrmap},
## from the YCbCr (luminance, chrominance blue, and chrominance red)
## color space to RGB values.  @var{YCbCr} must be of class double, single,
## uint8, or uint16.
##
## The formula used for the conversion is dependent on two constants, @var{Kb}
## and @var{Kr} which can be specified individually, or according to existing
## standards:
##
## @table @asis
## @item "601" (default)
## According to the ITU-R BT.601 (formerly CCIR 601) standard.  Its values
## of @var{Kb} and @var{Kr} are 0.114 and 0.299 respectively.
## @item "709" (default)
## According to the ITU-R BT.709 standard.  Its values of @var{Kb} and
## @var{Kr} are 0.0722 and 0.2116 respectively.
## @end table
##
## @seealso{hsv2rgb, ntsc2rgb, rgb2hsv, rgb2ntsc, rgb2ycbcr}
## @end deftypefn

function rgb = ycbcr2rgb (ycbcr, standard = "601")
  if (nargin < 1 || nargin > 2)
    print_usage ();
  endif
  rgb = ycbcrfunc ("ycbcr2rgb", ycbcr, standard);
endfunction

%!assert (ycbcr2rgb (rgb2ycbcr (jet (10))), jet (10), 0.00001);

## Copyright (C) 2013 CarnĂŤ Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.

## Private function for ycbcr2rgb and rgb2ycbcr functions which are
## very similar

function out = ycbcrfunc (func, in, standard)

  img = false; # was input an image?
  if (iscolormap (in))
    ## do nothing, it's a colormap
  elseif (isrgb (in))
    img = true;
    ## we shape it as a colormap (2D matrix) so we can use matrix multiplcation
    nRows = rows (in);
    nCols = columns (in);
    in    = reshape (in, [nRows*nCols 3]);
  else
    error ("%s: input must be a colormap (Nx3) or RGB image (NxMx3)", func);
  endif

  if (ischar (standard))
    if (strcmpi (standard, "601")) # for ITU-R BT.601
      Kb = 0.114;
      Kr = 0.299;
    elseif (strcmpi (standard, "709")) # for ITU-R BT.709
      Kb = 0.0722;
      Kr = 0.2126;
    else
      error ("%s: unknown standard `%s'", func, standard);
    endif
  elseif (isnumeric (standard) && numel (standard) == 2)
    Kb = standard(1);
    Kr = standard(2);
  else
    error ("%s: must specify a standard (string), or Kb and Kr values", func);
  endif

  ## the color matrix for the conversion. Derived from:
  ##    Y  = Kr*R + (1-Kr-Kb)*G + kb*B
  ##    Cb = (1/2) * ((B-Y)/(1-Kb))
  ##    Cr = (1/2) * ((R-Y)/(1-Kr))
  ## It expects RGB values in the range [0 1], and returns Y in the
  ## range [0 1], and Cb and Cr in the range [-0.5 0.5]
  cmat = [  Kr            (1-Kr-Kb)            Kb
          -(Kr/(2-2*Kb)) -(1-Kr-Kb)/(2-2*Kb)   0.5
            0.5          -(1-Kr-Kb)/(2-2*Kr) -(Kb/(2-2*Kr)) ];

  cls = class (in);
  in  = im2double (in);

  ## note that these blocks are the inverse of one another. Changes
  ## in one will most likely require a change on the other
  if (strcmp (func, "rgb2ycbcr"))
    ## convert to YCbCr colorspace
    out = (cmat * in')'; # transpose at the end to get back colormap shape
    ## rescale Cb and Cr to range [0 1]
    out(:, [2 3]) += 0.5;
    ## footroom and headroom will take from the range 16/255 each for Cb and Cr,
    ## and 16/255 and 20/255 for Y. So we have to compress the values of the
    ## space, and then shift forward
    out(:,1)     = (out(:,1) * 219/255) + 16/255;
    out(:,[2 3]) = (out(:,[2 3]) * 223/255) + 16/255;

  elseif (strcmp (func, "ycbcr2rgb"))
    ## just the inverse of the rgb2ycbcr conversion
    in(:,[2 3])  = (in(:,[2 3]) - 16/255) / (223/255);
    in(:,1)      = (in(:,1) - 16/255) / (219/255);
    in(:,[2 3]) -= 0.5;
    out          = (inv (cmat) * in')';
  else
    error ("internal error for YCbCr conversion. Unknown function %s", func);
  endif

  switch (cls)
    case {"single", "double"}
      ## do nothing. All is good
    case "uint8"
      out = im2uint8 (out);
    case "uint16"
      out = im2uint16 (out);
    otherwise
      error ("%s: unsupported image class %s", func, cls);
  endswitch

  if (img)
    ## put the image back together
    out = reshape (out, [nRows nCols 3]);
  endif

endfunction

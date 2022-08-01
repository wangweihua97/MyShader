import PIL.Image as img
import sys
tp=img.open(sys.argv[1])
tp.transpose(img.FLIP_LEFT_RIGHT).save(sys.argv[2])
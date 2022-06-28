from skimage.io import imread

im = imread('ship.png', as_gray=True)
#im = imread('ship_explosion.png', as_gray=True)
#im = imread('missile_explosion.png', as_gray=True)
#im = imread('mine1.png', as_gray=True)
#im = imread('mine2.png', as_gray=True)
#im = imread('mine1_explosion.png', as_gray=True)
#im = imread('mine2_explosion.png', as_gray=True)
#im = imread('tunnel.png', as_gray=True)

h, w = im.shape
s = ''
for i in range(h):
    s += '"'
    for j in range(w):
        s += str(int(im[i,j])^1) # use ^ to toggle it;
    s += '"'
    if i == h-1:
        s += ' '
    else:
        s += ','
    s += ' --' + str(i) + '\n'

file = open('ship.txt','w')
#file = open('ship_explosion.txt','w') 
#file = open('missile_explosion.txt','w') 
#file = open('mine1.txt','w') 
#file = open('mine2.txt','w') 
#file = open('mine1_explosion.txt','w')
#file = open('mine2_explosion.txt','w')
#file = open('tunnel.txt','w')

file.write(s) 
file.close()

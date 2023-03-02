# graph plot script. no manual array input

import sys
import matplotlib.pyplot as plt

str = sys.argv[5].split(" vs ")
strX = sys.argv[1].replace('[', ' ').replace(']', ' ').replace(',', ' ').split()
print(strX)
strY1 = sys.argv[2].replace('[', ' ').replace(']', ' ').replace(',', ' ').replace('\'', '').split()
print(strY1)
strY2 = sys.argv[3].replace('[', ' ').replace(']', ' ').replace(',', ' ').replace('\'', '').split()
print(strY2)
strY3 = sys.argv[4].replace('[', ' ').replace(']', ' ').replace(',', ' ').replace('\'', '').split()

X = [int(i) for i in strX]
Y1 = [float(i) for i in strY1]
Y2 = [float(i) for i in strY2]
Y3 = [float(i) for i in strY3]

Z1 = [0 for i in range(len(Y1))]

for i in range(len(Y1)):
    if Y1[i] != 0:
        Z1[i] = (Y2[i] - Y1[i])*100/Y1[i]
    else:
        Z1[i] = 0

Z2 = [0 for i in range(len(Y3))]

for i in range(len(Y3)):
    if Y3[i] != 0:
        Z2[i] = (Y2[i] - Y3[i])*100/Y3[i]
    else:
        Z2[i] = 0

plt.title(sys.argv[5])
plt.xlabel(str[1])
plt.ylabel(str[0])

plt.plot(X, Y1, 'g.-')
plt.plot(X, Y3, 'b.-')
plt.plot(X, Y2, 'r.-')

plt.legend(['existing', 'existing_vegas', 'modified_vegas'])
plt.grid()

plt.savefig('graphs_compare/' + sys.argv[6] + '.png', bbox_inches='tight', dpi=199)

plt.clf()

str = sys.argv[7].split(" vs ")
plt.title(sys.argv[7])
plt.xlabel(str[1])
plt.ylabel(str[0])

plt.plot(X, Z1, 'r.-')
plt.plot(X, Z2, 'b.-')

plt.legend(['tcp_tahoe vs modified_vegas', 'existing_vegas vs modified_vegas'])
plt.grid()

plt.savefig('graphs_compare/' + sys.argv[8] + '.png', bbox_inches='tight', dpi=199)
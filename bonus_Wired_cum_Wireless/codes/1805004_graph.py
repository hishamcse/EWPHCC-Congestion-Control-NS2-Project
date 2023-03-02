# graph plot script. no manual array input

import sys
import matplotlib.pyplot as plt

str = sys.argv[3].split(" vs ")
strX = sys.argv[1].replace('[', ' ').replace(']', ' ').replace(',', ' ').split()
print(strX)
strY = sys.argv[2].replace('[', ' ').replace(']', ' ').replace(',', ' ').split()
print(strY)

X = [int(i) for i in strX]
Y = [float(i) for i in strY]

plt.title(sys.argv[3])
plt.xlabel(str[1])
plt.ylabel(str[0])

plt.plot(X, Y, 'g.-')
plt.grid()

if sys.argv[5] == '1':
    plt.savefig('graphs_before/' + sys.argv[4] + '.png', bbox_inches='tight', dpi=199)
elif sys.argv[5] == '2':
    plt.savefig('graphs_after/' + sys.argv[4] + '.png', bbox_inches='tight', dpi=199)
else:
    plt.savefig('graphs_vegas_before/' + sys.argv[4] + '.png', bbox_inches='tight', dpi=199)

import matplotlib.pyplot as plt
from collections import Counter

rows = [
    "1,8,16,18,19,26,27,30,32,48,49",
    "1,8,16,18,19,26,27,30,32,48,49",
    "1,8,16,18,19,26,27,30,32,48,49",
    "1,28",
    "13,14,15,20,21,22,27,25",
    "5,6,7,27",
    "13,14,15,20,21,22,27,25",
    "5,6,7,27",
    "5,6,7,27",
    "1,2,3,4,5,6,7,8,9,10,11,16,17,19,20,21,22,23,26,28,31,32",
    "1,2,3,4,5,6,7,8,9,10,11,16,17,19,20,21,22,23,26,28,31,3",
    "38,39,40,1,2,3,4,5,6,7,8,9,10,11,16,17,19,20,21,22,23,26,28,31,32",
    "38,39,40,1,2,3,4,5,6,7,8,9,10,11,16,17,19,20,21,22,23,26,28,31,32",
    "17,26,27,40",
    "46,40,45,47",
    "1,2,16,18,19,21,26,",
    "1,2,16,18,19,21,26,",
    "1,2,16,18,19,21,26,",
    "1,2,16,18,19,21,26,",
    "1,2,16,18,19,21,26,",
    "1,7,40"
]

freq = Counter()

for line in rows:
    # split by comma, strip whitespace, ignore empty
    nums = [int(x.strip()) for x in line.split(",") if x.strip() != ""]
    uniq = set(nums)
    freq.update(uniq)

for n in sorted(freq):
    print(n, freq[n])


observed = sorted(freq.keys())
counts = [freq[n] for n in observed]

plt.figure(figsize=(12,6))
plt.bar(observed, counts, color="skyblue")
plt.xlabel("Number")
plt.ylabel("Frequency (rows containing the number)")
plt.title("Frequency of each number across rows (per-row unique)")
plt.xticks(range(min(observed), max(observed)+1))
plt.tight_layout()
plt.show()
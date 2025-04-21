import os
import glob
import matplotlib.pyplot as plt
import numpy as np


def get_total_insns(file_path):
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
            for line in lines:
                if 'total insns:' in line:
                    return int(line.split(':')[1].strip())
    except:
        return 0


# Configurations to analyze
configs = ['riscv-spec-ref', 'riscv-rev-spec-ref']

# Dictionary to store results
results = {}

# Process each configuration
for config in configs:
    path = f'./{config}/output'
    if os.path.exists(path):
        log_files = glob.glob(f'{path}/*.log')

        for log_file in log_files:
            # Extract benchmark name from filename
            benchmark = os.path.basename(log_file).split('.')[0]

            if benchmark not in results:
                results[benchmark] = {}

            # Get total instructions
            total_insns = get_total_insns(log_file)

            if results[benchmark].get(config) is None:
                results[benchmark][config] = total_insns
            else:
                # add the total insns to the existing value
                results[benchmark][config] += total_insns

# Prepare data for plotting
benchmarks = list(results.keys())
spec_data = [results[b].get('riscv-spec-ref', 0) for b in benchmarks]
rev_data = [results[b].get('riscv-rev-spec-ref', 0) for b in benchmarks]
cost1_data = [results[b].get('riscv-cost1-spec-ref', 0) for b in benchmarks]
for b in benchmarks:
    print(f"Benchmark: {b}")
    print(f"original : {results[b].get('riscv-spec-ref', 0)}")
    print(f"rev : {results[b].get('riscv-rev-spec-ref', 0)}")
    print(f"rev / spec: {results[b].get('riscv-rev-spec-ref', 0) / results[b].get('riscv-spec-ref', 1)}")
    print("--------------------------------------------------------------")
# Create bar chart
x = np.arange(len(benchmarks))
width = 0.25

fig, ax = plt.subplots(figsize=(12, 6))
rects1 = ax.bar(x - width, spec_data, width, label='spec-ref')
rects2 = ax.bar(x, rev_data, width, label='rev-spec-ref')
# # Add labels to bars
# def add_labels(rects):
#     for rect in rects:
#         height = rect.get_height()
#         ax.annotate(f'{height}',
#                     xy=(rect.get_x() + rect.get_width() / 2, height),
#                     xytext=(0, 3),  # 3 points vertical offset
#                     textcoords="offset points",
#                     ha='center', va='bottom')


# Customize chart
ax.set_ylabel('Total Instructions')
ax.set_title('Instruction Count Comparison Across Configurations')
ax.set_xticks(x)
ax.set_xticklabels(benchmarks, rotation=45)
ax.legend()

# Format y-axis to use scientific notation
ax.yaxis.set_major_formatter(plt.ScalarFormatter(useMathText=True))
plt.ticklabel_format(style='sci', axis='y', scilimits=(0, 0))

# Adjust layout to prevent label cutoff
plt.tight_layout()

# Save the plot
plt.savefig('instruction_count_comparison.png')
plt.close()

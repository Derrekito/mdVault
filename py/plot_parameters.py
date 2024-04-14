import matplotlib.pyplot as plt

def set_plot_parameters():
    plt.rcParams['axes.titlepad'] = 20  # Set padding for axis titles
    plt.rcParams['axes.titlesize'] = 20  # Set font size for axis titles
    plt.rcParams['axes.labelsize'] = 16  # Set font size for axis labels
    plt.rcParams['xtick.labelsize'] = 14  # Set font size for x-axis tick labels
    plt.rcParams['ytick.labelsize'] = 14  # Set font size for y-axis tick labels
    plt.rcParams['legend.fontsize'] = 14  # Set font size for legend
    plt.rcParams['figure.autolayout'] = True  # Adjust layout automatically to fill the entire figure
    plt.rcParams['figure.subplot.wspace'] = 0  # Set horizontal white space padding to 0
    plt.rcParams['figure.subplot.hspace'] = 0  # Set vertical white space padding to 0

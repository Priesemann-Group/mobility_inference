## NOT IN USE ANYMORE | plot Gamma distribution with inferred mean and standard deviation
def plot_gamma_kernel_kurzarbeit(trace_in, tag_in):
    fig, ax = plt.subplots(1, 1, figsize=(5, 4))

    # prepare
    max_x = 4
    x = np.linspace(0, max_x, 100)
    ys = []

    # plot
    y = cov19.model._utility.tt_gamma(
        x,
        mu=np.median(trace_in.posterior[f"mu_K"]),
        sigma=np.median(trace_in.posterior[f"sigma_K"]),
    ).eval()
    ys.append(y)
    ax.plot(x, y, linewidth=3, color=colors["K"])

    # format
    ax.set_xlabel("Month")
    ax.set_title("Inferred median Gamma\nkernel for Kurzarbeit")
    ax.set_xlim(0, max_x)
    ax.set_ylim(0, 1.1 * np.max(np.array(ys)))
    fig.tight_layout()

    fig.savefig(f"{tag_in}/gamma_kernel_kurzarbeit.png")
    fig.savefig(f"{tag_in}/gamma_kernel_kurzarbeit.pdf")

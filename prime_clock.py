import datetime
import primefac
import click
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from typing import Dict
from pathlib import Path
import sys
import os
import logging

logging.basicConfig(level=logging.INFO)

max_num = 60 # Highest number to support
potential_factors = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59] # All possible prime factors for numbers in [0, 60]
cache_file_path = Path("./decomp_cache.csv") # Where to save the prime number decomposition cache
refresh_cache=False # Whether to regenerate the prime number decomposition cache

def pf_rep(comp_num: int) -> pd.DataFrame:
    """Take a composite number, make a prime factor decomposition 
    and represent as vector in inf-dimensional prime basis space.

    Args:
        comp_num (int): Input composite number to factorize

    Returns:
        pd.DataFrame: dataframe with one row counting the prime factors (in each column)
    """
    prime_nums = primefac.primefac(comp_num)
    prime_histogram = pd.DataFrame(data = [[0]*len(potential_factors)], columns=potential_factors)
    for n in prime_nums:
        prime_histogram.loc[0, n] += 1
    return prime_histogram

def cache_factorization(cache_file_path: Path) -> None:
    """Cache numbers' prime factorization in a CSV file.

    Args:
        cache_file_path (Path): Where to save the cached numbers as CSV)
    """
    factors = pd.concat([pf_rep(x) for x in range(max_num+1)]).reset_index(drop=True)
    factors.to_csv(cache_file_path, index=False)
    return

def polar_plot(time_decomp: pd.DataFrame, output_file: Path, time_str: str):
    """Generate a polar plot of the time decomposition and save it as PNG

    Args:
        time_decomp (pd.DataFrame): A DF with a row for each decomposed number, the columns all potential factors
        output_file (Path): File to save polar plot to
    """
    num_prime_factors = len(potential_factors)
    theta = (2 * np.pi) * np.linspace(1 + 0.25,  0.25, num_prime_factors, endpoint=False) # Distribute theta evenly over all prime factors, and start from top of circle clockwise
    # if all

    def num_wrap(num: float, r_min: float, r_max: float) -> float:
        """"Make sure a given number is within range [r_min, r_max] by making it wrap around"""
        range_len = r_max -r_min
        if num<r_min:
            add_factors = np.ceil((r_min - num)/range_len)
            return num + range_len * add_factors
        elif num>r_max:
            sub_factors = np.ceil((num - r_max)/range_len)
            return num - range_len * sub_factors
        else:
            return num
    theta = [num_wrap(n, 0, 2*np.pi) for n in theta]

    r_hours = time_decomp.iloc[0].to_numpy()
    r_minutes = time_decomp.iloc[1].to_numpy()
    r_seconds = time_decomp.iloc[2].to_numpy()

    fig, ax = plt.subplots(subplot_kw={'projection': 'polar'})

    widths = [(2 * np.pi)/num_prime_factors] * num_prime_factors
    ax.bar(theta, r_hours, width=widths, bottom=0.0, color='red', alpha=0.5, label='hours', edgecolor='k')
    ax.bar(theta, r_minutes, width=widths, bottom=0.0, color='blue', alpha=0.5, label='minutes', edgecolor='k')
    ax.bar(theta, r_seconds, width=widths, bottom=0.0, color='green', alpha=0.5, label='seconds', edgecolor='k')

    #ax.set_ylim([0,3])
    ax.set_rticks([1, 2, 3, 4, 5])  # Less radial ticks
    ax.set_rlim(bottom=5, top=0)

    ax.set_xticks(theta)
    ax.set_xticklabels([str(f) for f in potential_factors])
    #ax.set_rlabel_position(-22.5)  # Move radial labels away from plotted line
    #ax.grid(True)
    ax.set_title(f"Prime number decomposition plot at {time_str}", va='bottom')
    legend_angle = np.deg2rad(67.5)
    ax.legend(loc="upper left", bbox_to_anchor=(.8 + np.cos(legend_angle)/2, .5 + np.sin(legend_angle)/2))
    plt.savefig(output_file)

    logging.info("Saved output plot to file")
    return

@click.command()
@click.argument('hours', type=int)
@click.argument('minutes', type=int)
@click.argument('seconds', type=int)
@click.option('--image', '-i', default=Path('prime_time.png'), help='Generate polar plot of prime decomposition', type=Path)
def cli(hours: int, minutes: int, seconds: int, image: Path):
    """Take a time in hours, minutes and seconds and print a prime decomposition of the numbers.
    Also make a polar plot to visualize and save it to disk.

    Args:
        hours (int): Hour hand
        minutes (int): Minute hand
        seconds (int): Second hand
        image (Path): Output plot path
    """

    if refresh_cache == True:
        logging.info("Regenerating cache")
        cache_factorization(cache_file_path)
    try:
        logging.info("Using prime decomposition cache")
        decomp_lookup = pd.read_csv(cache_file_path)
    except:
        logging.error("Error reading prime decomposition cache")

    if hours == 0 and minutes == 0 and seconds == 0:
        cur_datetime = datetime.datetime.now()
        hours, minutes, seconds = int(cur_datetime.hour), int(cur_datetime.minute), int(cur_datetime.second)

    # Replace zeroes with the highest number (24 or 60) so we still have prime decompositions:
    # 1 will be then a unque number without factors
    hours = 24 if hours==0 else hours
    minutes = 60 if minutes==0 else minutes
    seconds = 60 if seconds==0 else seconds
    time_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"

    logging.info(f"Decomposing time {time_str}")
    prime_time = decomp_lookup.iloc[[hours, minutes, seconds]] #lookup prime decompositions of H:M:S
    print(f"Prime Time:\n{prime_time}")

    logging.info("Making time polar plot")
    polar_plot(time_decomp=prime_time, output_file=image, time_str=time_str)
    return


if __name__ == '__main__':
    cli()
import datetime
import primefac
import click
import pandas as pd

from typing import Dict
import sys
import logging

logging.basicConfig(level=logging.INFO)

# all possible prime factors for numbers in [0, 60]
potential_factors = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59]


def pf_rep(comp_num: int) -> pd.DataFrame:
    """Take a composite number, make a prime factor decomposition 
    and represent as vector in inf-dimensional prime basis space."""
    prime_nums = primefac.primefac(comp_num)
    prime_histogram = pd.DataFrame(data = [[0]*len(potential_factors)], columns=potential_factors)
    for n in prime_nums:
        prime_histogram.loc[0, n] += 1
    return prime_histogram

@click.command()
#@click.option('-h', '--hours', default=0, help='hour hand (in 24h format)')
@click.argument('hours')
#@click.option('-m', '--minutes', default=0, help='minute hand')
@click.argument('minutes')
#@click.option('-s', '--seconds', default=0, help='second hand')
@click.argument('seconds')
def cli(hours: str, minutes: str, seconds: str):
    """Take a time in hours, minutes and seconds and print a prime decomposition of the numbers."""
    hours = int(hours)
    minutes = int(minutes)
    seconds = int(seconds)

    if hours == 0 and minutes == 0 and seconds == 0:
        cur_datetime = datetime.datetime.now()
        hours, minutes, seconds = int(cur_datetime.hour), int(cur_datetime.minute), int(cur_datetime.second)

    logging.info(f"{hours:02d}:{minutes:02d}:{seconds:02d}")

    hours_p, minutes_p, seconds_p = pf_rep(hours), pf_rep(minutes), pf_rep(seconds)
    prime_time = pd.concat([hours_p, minutes_p, seconds_p])
    print(f"Prime Time:\n{prime_time.to_string(index=False)}")


if __name__ == '__main__':
    cli()
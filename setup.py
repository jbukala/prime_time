from setuptools import setup

setup(
    name='primeclock',
    version='0.1.0',
    py_modules=['prime_clock'],
    install_requires=[
        'Click',
    ],
    entry_points={
        'console_scripts': [
            'primeclock = prime_clock:cli',
        ],
    },
)
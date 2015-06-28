from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

ext_modules=[
    Extension("gazesdk",
              sources=["gazesdk.pyx"],
              libraries=["TobiiGazeCore32"]
    )
]

setup(
  name = "gazesdk",
  ext_modules = cythonize(ext_modules)
)
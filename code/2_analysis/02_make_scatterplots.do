/*******************************************************************************
Description: This file produces all scatterplots in the paper. Thus, it generates
	Figures 2b, 2d, 2f, 3b, and Appendix Figures A1b, A1d, A2, A3, A4b, A4d, 
	A5, A6, A7, A8.
*******************************************************************************/

clear all
set more off

/*********************
* MAKE SCATTERPLOTS
*********************/

* figure 2b
do "code/2_analysis/scatterplots/fig2b.do"

* figure 2d
do "code/2_analysis/scatterplots/fig2d.do"

* figure 2f
do "code/2_analysis/scatterplots/fig2f.do"

* figure 3b
do "code/2_analysis/scatterplots/fig3b.do"

* appendix figure A1b
do "code/2_analysis/scatterplots/figA1b.do"

* appendix figure A1d
do "code/2_analysis/scatterplots/figA1d.do"

* appendix figure A2
do "code/2_analysis/scatterplots/figA2.do"

* appendix figure A3
do "code/2_analysis/scatterplots/figA3.do"

* appendix figure A4b
do "code/2_analysis/scatterplots/figA4b.do"

* appendix figure A4d
do "code/2_analysis/scatterplots/figA4d.do"

* appendix figure A5
do "code/2_analysis/scatterplots/figA5.do"

* appendix figure A6
do "code/2_analysis/scatterplots/figA6.do"

* appendix figure A7
//do "code/2_analysis/scatterplots/figA7.do"

* appendix figure A8
do "code/2_analysis/scatterplots/figA8.do"

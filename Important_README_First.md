# MQL5-CODE

**This code will be hard to understand for someone unfamiliar with MQL5, unfamiliar with technical analysis and technical indicators but is similar in style to C++.**

Some redundencies commented out as I found better ways to do things. I left them commented out to assist with learning when I review. 

The video below explains the logic of the system and is very important to understand. 3 minutes long. 
https://www.youtube.com/watch?v=D0sFukv_d1g

**There is a virtual class for taking and recording trades. **
A) VirtualPosition2
B) A custom TDI indicator which takes moving averages and standard deviations of Wilder's relative strength index. 
C) There are exponential moving averages and one of which also contains a standard deviation. 
ASFX_TDI and ASFX_EMAs

In the near future my code will be moved to python.

Inspiration was from a company called asfx and I modified their entry to work on a smaller timeframe (scalping 5m) along with a higher time frame bias (trend)


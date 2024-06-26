#property link          "https://www.earnforex.com/metatrader-indicators/lot-size-calculator/"
#property version       "1.03"
#property strict
#property copyright     "EarnForex.com - 2020-2021"
#property description   "This indicator can calculate the ideal positions size and"
#property description   "show you the possible risk, profit and risk reward ratio."
#property description   " "
#property description   "Find More on EarnForex.com"
#property icon          "\\Files\\EF-Icon-64x64px.ico"
#property indicator_chart_window
#property indicator_plots 0

#include <MQLTA ErrorHandling.mqh>
#include <MQLTA Utils.mqh>


enum ENUM_PANEL_SIZE
  {
   PANEL_SMALL=1,    //SMALL
   PANEL_LARGE=2,    //LARGE
   PANEL_ULTRA=4,    //ULTRA WIDE
   PANEL_AUTO=5,     //AUTOMATIC
  };

enum DEF_MARKPEND
  {
   Market=0,      //MARKET ORDER
   Pending=1,     //PENDING ORDER
  };

enum DEF_SL
  {
   ByPts=0,       //BY POINTS
   ByPrice=1,     //BY PRICE
  };

enum ENUM_RISK_BASE
  {
   RISK_BALANCE=0,     //BALANCE
   RISK_EQUITY=1,      //EQUITY
   RISK_FREEMARGIN=2,  //FREE MARGIN
  };

enum ENUM_PENDING_TYPE
  {
   PENDING_STOP=0,   //STOP ORDER
   PENDING_LIMIT=1,  //LIMIT ORDER
  };

enum ENUM_PENDING_SIDE
  {
   PENDING_BUY=0,    //PENDING BUY
   PENDING_SELL=1,   //PENDING SELL
   PENDING_BUYSELL=2,//PENDING BUY AND SELL
  };

enum ENUM_PRICE_FOR_PENDING
  {
   PRICE_ASK=0,            //ASK PRICE
   PRICE_BID=1,            //BID PRICE
  };

enum ENUM_PENDING_START_PRICE_MODE
  {
   PENDING_START_CURRENT=0,   //CURRENT PRICE
   PENDING_START_MANUAL=1,    //MANUAL PRICE
  };

enum ENUM_LINE_ORDER_SIDE
  {
   LINE_ORDER_BUY=0,    //BUY
   LINE_ORDER_SELL=1,   //SELL
  };

enum ENUM_LINE_ORDER_TYPE
  {
   LINE_ORDER_MARKET=0,    //MARKET ORDER
   LINE_ORDER_STOP=1,      //PENDING STOP ORDER
   LINE_ORDER_LIMIT=2,     //PENDING LIMIT ORDER
  };

enum ENUM_LINE_TYPE
  {
   LINE_OPEN_PRICE=0,   //OPEN PRICE
   LINE_SL_PRICE=1,     //STOP LOSS PRICE
   LINE_TP_PRICE=2,     //TAKE PROFIT LINE
   LINE_ALL=3,          //ALL LINES
  };


input string Comment_1="====================";           //Position Size Calculator
input string IndicatorName="LSC";                        //Indicator Name (used to draw objects)

input string Comment_2="====================";           //Default Settings
DEF_MARKPEND DefaultMarketPending=Market;          //Default Type of Order
input double DefaultTickValue=5;
input double DefaultLotSize=0.01;                           //Default Lot Size
input double DefaultLotStep=0.01;                           //Default Increment/Decrement of size
input DEF_SL DefaultSLBy=ByPrice;                          //Default Stop Loss Type
int DefaultSLPts=0;                                //Default Stop Loss in Points
int DefaultTPPts=0;                                //Default Take Profit in Points
input ENUM_RISK_BASE DefaultRiskBase=RISK_EQUITY;       //Default Risk Calculation Base
input double DefaultRiskPerc=5;                          //Default % of Risk

input string Comment_2a="====================";          //Additional Default For Lines
input bool ShowSLTPPts=true;                             //Show Stop Loss And Take Profit Points
input bool ShowSLTPPrice=true;                           //Show Stop Loss And Take Profit Prices
input bool ShowSLTPAmount=true;                          //Show Stop Loss And Take Profit Amounts
input bool ShowRiskBase=true;                            //Show Risk Base
input bool ShowRiskPerc=true;                            //Show Risk Percentage
input bool ShowRiskAmount=true;                          //Show Risk Amount
input bool ShowRRR=true;                                 //Show Risk Reward Ratio


input string Comment_2b="====================";          //Additional Default For Lines
ENUM_LINE_ORDER_SIDE DefaultOrderLineSide=LINE_ORDER_BUY;   //Default Order Side
ENUM_LINE_ORDER_TYPE DefaultOrderLineType=LINE_ORDER_MARKET;//Default Order Type
input color LineOpenPriceColor=clrGray;                  //Open Price Line Color
input color LineSLPriceColor=clrRed;                     //Stop Loss Price Line Color
input color LineTPPriceColor=clrGreen;                   //Take Profit Price Line Color
input ENUM_LINE_STYLE LineStyle=STYLE_DASH;              //Line Style

input string Comment_4="====================";           //Colors and Position
extern int Xoff=20;                                      //Horizontal spacing for the control panel
extern int Yoff=20;                                      //Vertical spacing for the control panel
input int NOFontSize=8;                                  //Font Size
input ENUM_PANEL_SIZE PanelSize=PANEL_AUTO;              //Panel Size
input bool ShowURL=false;                                 //Show Website URL


int CurrMarketPending=Market;
int CurrSLPtsOrPrice=ByPts;
int CurrLinesSide=DefaultOrderLineSide;
int CurrLinesType=DefaultOrderLineType;
double CurrLotSize=0;
double CurrSLPrice=0;
double CurrTPPrice=0;
double CurrSLPts=0;
double CurrTPPts=0;
double CurrSLAmount=0;
double CurrTPAmount=0;
double CurrOpenPrice=0;
double TickValue=0;
long CurrMagic=0;
string CurrComment="";
bool NewOrderPanelOpen=false;

string NOFont="Consolas";

double LotSize=DefaultLotSize;
double LotStep=DefaultLotStep;
double CurrRiskPerc=0;
double CurrRiskAmount=0;
double CurrRRRatio=0;
int CurrRiskBase=RISK_BALANCE;
int eDigits=0;
int PanelSizeMultiplier=1;

bool NewOrderPanelIsOpen=false;
bool NewOrderLinesPanelIsOpen=false;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

   IndicatorSetString(INDICATOR_SHORTNAME,IndicatorName);

   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1);
   ChartSetInteger(0,CHART_EVENT_OBJECT_DELETE,1);
   CleanChart();
   InitializeDefaults();
   CreateMiniPanel();
   TickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
   if(TickValue==0.0)
     {
      TickValue = DefaultTickValue;
     }

   return(INIT_SUCCEEDED);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   CleanChart();


  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   if(NewOrderLinesPanelIsOpen)
     {
      if(CurrSLPrice!=0 || CurrTPPrice!=0)
        {
         ShowNewOrderLines();
        }
     }
   return 0;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {

   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam==PanelLines)
        {
         if(NewOrderLinesPanelIsOpen)
           {
            DeleteNewOrderLine(LINE_ALL);
            CloseNewOrderLines();
           }
         else
           {
            InitializeDefaults();
            DeleteNewOrderLine(LINE_ALL);
            ShowNewOrderLines();
           }
        }
      if(sparam==NewOrderLinesLotMinus)
        {
         DecrementSize();
        }
      if(sparam==NewOrderLinesLotPlus)
        {
         IncrementSize();
        }
      if(sparam==NewOrderLinesRecommendedSize)
        {
         ChangeRecommendedSize();
        }
      if(sparam==NewOrderLinesSide)
        {
         ChangeLinesOrderSide();
        }
      if(sparam==NewOrderLinesOrderType)
        {
         ChangeLinesOrderType();
        }
      if(sparam==NewOrderLinesTargetIntro)
        {
         ChangeSLPtsPrice();
        }
      if(sparam==NewOrderLinesSLPrice && CurrSLPtsOrPrice==ByPrice)
        {
         ClickNewOrderLinesSLPrice();
        }
      if(sparam==NewOrderLinesTPPrice && CurrSLPtsOrPrice==ByPrice)
        {
         ClickNewOrderLinesTPPrice();
        }
      if(sparam==NewOrderLinesRiskBaseE)
        {
         ChangeLinesRiskBase();
        }
     }

   if(id==CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(sparam==NewOrderLinesLotSize)
        {
         ChangeSize();
        }
      if(sparam==NewOrderLinesSLPriceE)
        {
         ChangeSLPrice();
        }
      if(sparam==NewOrderLinesTPPriceE)
        {
         ChangeTPPrice();
        }
      if(sparam==NewOrderLinesSLPtsE)
        {
         ChangeSLPts();
        }
      if(sparam==NewOrderLinesTPPtsE)
        {
         ChangeTPPts();
        }
      if(sparam==NewOrderLinesRiskPercE)
        {
         ChangeRiskPerc();
        }
      if(sparam==NewOrderLinesPendingOpenPriceE)
        {
         ChangePendingOpenPrice();
        }
      if(sparam==NewOrderLinesRiskAmountE)
        {
         ChangeRiskAmount();
        }
     }

   if(id==CHARTEVENT_OBJECT_DRAG)
     {
      if(sparam==LineNameOpen)
        {
         UpdatePriceByLine(LineNameOpen);
        }
      if(sparam==LineNameSL)
        {
         UpdatePriceByLine(LineNameSL);
        }
      if(sparam==LineNameTP)
        {
         UpdatePriceByLine(LineNameTP);
        }
     }

   if(id==CHARTEVENT_OBJECT_DELETE)
     {
      if(sparam==LineNameOpen || sparam==LineNameSL || sparam==LineNameTP)
        {
         UpdateLinesDeleted(sparam);
        }
     }

   if(id==CHARTEVENT_CHART_CHANGE)
     {
      if(NewOrderLinesPanelIsOpen)
        {
         UpdateLinesLabels();
         ShowNewOrderLines();
        }
     }

   if(id==CHARTEVENT_KEYDOWN)
     {
      if(lparam==27)
        {
         ChartIndicatorDelete(0,0,IndicatorName);
        }
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitializeDefaults()
  {
   CurrMarketPending=DefaultMarketPending;
   CurrSLPtsOrPrice=DefaultSLBy;
   CurrLinesSide=DefaultOrderLineSide;
   CurrLinesType=DefaultOrderLineType;
   CurrRiskPerc=DefaultRiskPerc;
   CurrRiskBase=DefaultRiskBase;
   CurrLotSize=DefaultLotSize;
   LotStep=DefaultLotStep;
   CurrSLPrice=0;
   CurrTPPrice=0;
   CurrSLPts=DefaultSLPts;
   CurrTPPts=DefaultTPPts;
   CurrSLAmount=0;
   CurrTPAmount=0;
   CurrRRRatio=0;
   CurrOpenPrice=Close[0];
   eDigits=(int)MarketInfo(Symbol(),MODE_DIGITS);
   SetPanelSize();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetPanelSize()
  {
   if(PanelSize==PANEL_SMALL)
      PanelSizeMultiplier=1;
   if(PanelSize==PANEL_LARGE)
      PanelSizeMultiplier=2;
   if(PanelSize==PANEL_ULTRA)
      PanelSizeMultiplier=4;
   if(PanelSize==PANEL_AUTO)
     {
      int ChartWidthPixel=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
      if(ChartWidthPixel>2000 && ChartWidthPixel<3000)
         PanelSizeMultiplier=2;
      if(ChartWidthPixel>3000)
         PanelSizeMultiplier=4;
     }
   return;
  }


string PanelBase=IndicatorName+"-BAS";
string PanelMove=IndicatorName+"-MOV";
string PanelList=IndicatorName+"-LST";
string PanelOptions=IndicatorName+"-OPT";
string PanelClose=IndicatorName+"-CLO";
string PanelLabel=IndicatorName+"-LAB";
string PanelExp=IndicatorName+"-EXP";
string PanelPend=IndicatorName+"-PEND";
string PanelLines=IndicatorName+"-LINES";

int PanelMovX=26*PanelSizeMultiplier;
int PanelMovY=26*PanelSizeMultiplier;
int PanelLabX=181*PanelSizeMultiplier;
int PanelLabY=PanelMovY;
int PanelRecX=(PanelMovX+1)*1+PanelLabX+4;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateMiniPanel()
  {
   PanelMovX=26*PanelSizeMultiplier;
   PanelMovY=26*PanelSizeMultiplier;
   PanelLabX=181*PanelSizeMultiplier;
   PanelLabY=PanelMovY;
   PanelRecX=(PanelMovX+1)*1+PanelLabX+4;
   ObjectCreate(0,PanelBase,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSet(PanelBase,OBJPROP_XDISTANCE,Xoff);
   ObjectSet(PanelBase,OBJPROP_YDISTANCE,Yoff);
   ObjectSetInteger(0,PanelBase,OBJPROP_XSIZE,PanelRecX);
   ObjectSetInteger(0,PanelBase,OBJPROP_YSIZE,PanelMovY+2*2);
   ObjectSetInteger(0,PanelBase,OBJPROP_BGCOLOR,White);
   ObjectSetInteger(0,PanelBase,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,PanelBase,OBJPROP_STATE,false);
   ObjectSetInteger(0,PanelBase,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,PanelBase,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSet(PanelBase,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,PanelBase,OBJPROP_COLOR,clrBlack);

   ObjectCreate(0,PanelLines,OBJ_EDIT,0,0,0);
   ObjectSet(PanelLines,OBJPROP_XDISTANCE,Xoff+PanelLabX+(PanelMovX+1)*0+3);
   ObjectSet(PanelLines,OBJPROP_YDISTANCE,Yoff+2);
   ObjectSetInteger(0,PanelLines,OBJPROP_XSIZE,PanelMovX);
   ObjectSetInteger(0,PanelLines,OBJPROP_YSIZE,PanelMovX);
   ObjectSetInteger(0,PanelLines,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,PanelLines,OBJPROP_STATE,false);
   ObjectSetInteger(0,PanelLines,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,PanelLines,OBJPROP_READONLY,true);
   ObjectSetInteger(0,PanelLines,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,PanelLines,OBJPROP_TOOLTIP,"Position Size Calculator Panel");
   ObjectSetInteger(0,PanelLines,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,PanelLines,OBJPROP_FONT,"Wingdings");
   ObjectSetString(0,PanelLines,OBJPROP_TEXT,"7");
   ObjectSet(PanelLines,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,PanelLines,OBJPROP_COLOR,clrNavy);
   ObjectSetInteger(0,PanelLines,OBJPROP_BGCOLOR,clrKhaki);
   ObjectSetInteger(0,PanelLines,OBJPROP_BORDER_COLOR,clrBlack);

   ObjectCreate(0,PanelLabel,OBJ_EDIT,0,0,0);
   ObjectSet(PanelLabel,OBJPROP_XDISTANCE,Xoff+2);
   ObjectSet(PanelLabel,OBJPROP_YDISTANCE,Yoff+2);
   ObjectSetInteger(0,PanelLabel,OBJPROP_XSIZE,PanelLabX);
   ObjectSetInteger(0,PanelLabel,OBJPROP_YSIZE,PanelLabY);
   ObjectSetInteger(0,PanelLabel,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,PanelLabel,OBJPROP_STATE,false);
   ObjectSetInteger(0,PanelLabel,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,PanelLabel,OBJPROP_READONLY,true);
   ObjectSetInteger(0,PanelLabel,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,PanelLabel,OBJPROP_TOOLTIP,"Lot Size And Risk Reward Ratio Calculator");
   ObjectSetString(0,PanelLabel,OBJPROP_TEXT,"LOT SIZE AND RRR");
   ObjectSetString(0,PanelLabel,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(0,PanelLabel,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSet(PanelLabel,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,PanelLabel,OBJPROP_COLOR,clrNavy);
   ObjectSetInteger(0,PanelLabel,OBJPROP_BGCOLOR,clrKhaki);
   ObjectSetInteger(0,PanelLabel,OBJPROP_BORDER_COLOR,clrBlack);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeRecommendedSize()
  {
   if(RecommendedSize()>0)
     {
      double TextLotSize=NormalizeDouble(RecommendedSize(),2);
      if(NewOrderLinesPanelIsOpen)
         ObjectSetString(0,NewOrderLinesLotSize,OBJPROP_TEXT,DoubleToString(TextLotSize,2));
     }
   ChangeSize();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void IncrementSize()
  {
   CurrLotSize+=LotStep;
   CurrLotSize=MathRound(CurrLotSize/MarketInfo(Symbol(),MODE_LOTSTEP))*MarketInfo(Symbol(),MODE_LOTSTEP);
   if(CurrLotSize>MarketInfo(Symbol(),MODE_MAXLOT))
     {
      MessageBox("The Maximum Position Size is "+DoubleToString(MarketInfo(Symbol(),MODE_MAXLOT), 2));
      CurrLotSize=MarketInfo(Symbol(),MODE_MAXLOT);
     }
   if(CurrLotSize<MarketInfo(Symbol(),MODE_MINLOT))
     {
      MessageBox("The Minimum Position Size is "+DoubleToString(MarketInfo(Symbol(),MODE_MINLOT), 2));
      CurrLotSize=MarketInfo(Symbol(),MODE_MINLOT);
     }
   if(NewOrderLinesPanelIsOpen)
      ShowNewOrderLines();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DecrementSize()
  {
   CurrLotSize-=LotStep;
   CurrLotSize=MathRound(CurrLotSize/MarketInfo(Symbol(),MODE_LOTSTEP))*MarketInfo(Symbol(),MODE_LOTSTEP);
   if(CurrLotSize>MarketInfo(Symbol(),MODE_MAXLOT))
     {
      MessageBox("The Maximum Position Size is "+DoubleToString(MarketInfo(Symbol(),MODE_MAXLOT), 2));
      CurrLotSize=MarketInfo(Symbol(),MODE_MAXLOT);
     }
   if(CurrLotSize<MarketInfo(Symbol(),MODE_MINLOT))
     {
      MessageBox("The Minimum Position Size is "+DoubleToString(MarketInfo(Symbol(),MODE_MINLOT), 2));
      CurrLotSize=MarketInfo(Symbol(),MODE_MINLOT);
     }
   if(NewOrderLinesPanelIsOpen)
      ShowNewOrderLines();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeSize()
  {
   if(NewOrderLinesPanelIsOpen)
      CurrLotSize=StringToDouble(ObjectGetString(0,NewOrderLinesLotSize,OBJPROP_TEXT));
   CurrLotSize=MathRound(CurrLotSize/MarketInfo(Symbol(),MODE_LOTSTEP))*MarketInfo(Symbol(),MODE_LOTSTEP);
   if(CurrLotSize>MarketInfo(Symbol(),MODE_MAXLOT))
     {
      MessageBox("The Maximum Position Size is "+DoubleToString(MarketInfo(Symbol(),MODE_MAXLOT), 2));
      CurrLotSize=MarketInfo(Symbol(),MODE_MAXLOT);
     }
   if(CurrLotSize<MarketInfo(Symbol(),MODE_MINLOT))
     {
      MessageBox("The Minimum Position Size is "+DoubleToString(MarketInfo(Symbol(),MODE_MINLOT), 2));
      CurrLotSize=MarketInfo(Symbol(),MODE_MINLOT);
     }
   if(NewOrderLinesPanelIsOpen)
      ShowNewOrderLines();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangePendingOpenPrice()
  {
   if(NewOrderLinesPanelIsOpen)
     {
      CurrOpenPrice=StringToDouble(ObjectGetString(0,NewOrderLinesPendingOpenPriceE,OBJPROP_TEXT));
      ShowNewOrderLines();
      UpdateLineByPrice(LineNameOpen);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeSLPrice()
  {
   CurrSLPrice=StringToDouble(ObjectGetString(0,NewOrderLinesSLPriceE,OBJPROP_TEXT));
   double Loss=0;
   double LossPts=0;
   double OpenPrice=0;
   RefreshRates();
   if(CurrLinesSide==LINE_ORDER_BUY && CurrLinesType==LINE_ORDER_MARKET)
     {
      OpenPrice=Ask;
     }
   if(CurrLinesSide==LINE_ORDER_SELL && CurrLinesType==LINE_ORDER_MARKET)
     {
      OpenPrice=Bid;
     }
   if(CurrLinesType!=LINE_ORDER_MARKET)
     {
      OpenPrice=CurrOpenPrice;
     }
   if(CurrLinesSide==LINE_ORDER_BUY)
     {
      if(CurrSLPrice!=0)
         CurrSLPts=(OpenPrice-CurrSLPrice)/Point;
     }
   if(CurrLinesSide==LINE_ORDER_SELL)
     {
      if(CurrSLPrice!=0)
         CurrSLPts=(CurrSLPrice-OpenPrice)/Point;
     }
   ShowNewOrderLines();
   UpdateLineByPrice(LineNameSL);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeTPPrice()
  {
   CurrTPPrice=StringToDouble(ObjectGetString(0,NewOrderLinesTPPriceE,OBJPROP_TEXT));
   double Profit=0;
   double ProfitPts=0;
   double OpenPrice=0;
   RefreshRates();
   if(CurrLinesSide==LINE_ORDER_BUY && CurrLinesType==LINE_ORDER_MARKET)
     {
      OpenPrice=Ask;
     }
   if(CurrLinesSide==LINE_ORDER_SELL && CurrLinesType==LINE_ORDER_MARKET)
     {
      OpenPrice=Bid;
     }
   if(CurrLinesType!=LINE_ORDER_MARKET)
     {
      OpenPrice=CurrOpenPrice;
     }
   if(CurrLinesSide==LINE_ORDER_BUY)
     {
      if(CurrTPPrice!=0)
         CurrTPPts=(CurrTPPrice-OpenPrice)/Point;
     }
   if(CurrLinesSide==LINE_ORDER_SELL)
     {
      if(CurrTPPrice!=0)
         CurrTPPts=(OpenPrice-CurrTPPrice)/Point;
     }
   ShowNewOrderLines();
   UpdateLineByPrice(LineNameTP);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeSLPts()
  {
   CurrSLPts=StringToDouble(ObjectGetString(0,NewOrderLinesSLPtsE,OBJPROP_TEXT));
   double Loss=0;
   double LossPts=0;
   double OpenPrice=0;
   RefreshRates();
   if(CurrLinesSide==LINE_ORDER_BUY && CurrLinesType==LINE_ORDER_MARKET)
     {
      OpenPrice=Ask;
     }
   if(CurrLinesSide==LINE_ORDER_SELL && CurrLinesType==LINE_ORDER_MARKET)
     {
      OpenPrice=Bid;
     }
   if(CurrLinesType!=LINE_ORDER_MARKET)
     {
      OpenPrice=CurrOpenPrice;
     }
   if(CurrLinesSide==LINE_ORDER_BUY)
     {
      if(CurrSLPts!=0)
         CurrSLPrice=OpenPrice-CurrSLPts*Point;
     }
   if(CurrLinesSide==LINE_ORDER_SELL)
     {
      if(CurrSLPts!=0)
         CurrSLPrice=OpenPrice+CurrSLPts*Point;
     }
   ShowNewOrderLines();
   UpdateLineByPrice(LineNameSL);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeTPPts()
  {
   CurrTPPts=StringToDouble(ObjectGetString(0,NewOrderLinesTPPtsE,OBJPROP_TEXT));
   double Profit=0;
   double ProfitPts=0;
   double OpenPrice=0;
   RefreshRates();
   if(CurrLinesSide==LINE_ORDER_BUY && CurrLinesType==LINE_ORDER_MARKET)
     {
      OpenPrice=Ask;
     }
   if(CurrLinesSide==LINE_ORDER_SELL && CurrLinesType==LINE_ORDER_MARKET)
     {
      OpenPrice=Bid;
     }
   if(CurrLinesType!=LINE_ORDER_MARKET)
     {
      OpenPrice=CurrOpenPrice;
     }
   if(CurrLinesSide==LINE_ORDER_BUY)
     {
      if(CurrTPPts!=0)
         CurrTPPrice=OpenPrice+CurrTPPts*Point;
     }
   if(CurrLinesSide==LINE_ORDER_SELL)
     {
      if(CurrTPPts!=0)
         CurrTPPrice=OpenPrice-CurrTPPts*Point;
     }
   ShowNewOrderLines();
   UpdateLineByPrice(LineNameTP);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeRiskPerc()
  {
   if(NewOrderLinesPanelIsOpen)
     {
      CurrRiskPerc=StringToDouble(ObjectGetString(0,NewOrderLinesRiskPercE,OBJPROP_TEXT));
      ShowNewOrderLines();
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeRiskAmount()
  {
   CurrRiskAmount=StringToDouble(ObjectGetString(0,NewOrderLinesRiskAmountE,OBJPROP_TEXT));
   if(CurrRiskBase==RISK_BALANCE)
      CurrRiskPerc=CurrRiskAmount/AccountBalance()*100;
   if(CurrRiskBase==RISK_EQUITY)
      CurrRiskPerc=CurrRiskAmount/AccountEquity()*100;
   if(CurrRiskBase==RISK_FREEMARGIN)
      CurrRiskPerc=CurrRiskAmount/AccountFreeMargin()*100;
   ShowNewOrderLines();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseNewOrder()
  {
   int Window=0;
   for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
     {
      if((StringFind(ObjectName(i),IndicatorName+"-NO-",0)>=0))
        {
         ObjectDelete(ObjectName(i));
        }
     }
   NewOrderPanelIsOpen=false;

  }


string NewOrderLinesBase=IndicatorName+"-NOL-Base";
string NewOrderLinesClose=IndicatorName+"-NOL-Close";
string NewOrderLinesOrder=IndicatorName+"-NOL-LinesOrder";
string NewOrderLinesPositionSize=IndicatorName+"-NOL-PosSize";
string NewOrderLinesRecommendedSize=IndicatorName+"-NOL-RecSize";
string NewOrderLinesPendingOpenPrice=IndicatorName+"-NOL-PendingOP";
string NewOrderLinesPendingOpenPriceE=IndicatorName+"-NOL-PendingOPE";
string NewOrderLinesSide=IndicatorName+"-NOL-Side";
string NewOrderLinesOrderType=IndicatorName+"-NOL-OrderType";
string NewOrderLinesLotMinus=IndicatorName+"-NOL-LotMinus";
string NewOrderLinesLotSize=IndicatorName+"-NOL-LotSize";
string NewOrderLinesLotPlus=IndicatorName+"-NOL-LotPlus";
string NewOrderLinesTargetIntro=IndicatorName+"-NOL-TargetIntro";
string NewOrderLinesSLPts=IndicatorName+"-NOL-SLPts";
string NewOrderLinesSLPtsE=IndicatorName+"-NOL-SLPtsE";
string NewOrderLinesTPPts=IndicatorName+"-NOL-TPPts";
string NewOrderLinesTPPtsE=IndicatorName+"-NOL-TPPtsE";
string NewOrderLinesSLPrice=IndicatorName+"-NOL-SLPrice";
string NewOrderLinesTPPrice=IndicatorName+"-NOL-TPPrice";
string NewOrderLinesSLPriceE=IndicatorName+"-NOL-SLPriceE";
string NewOrderLinesTPPriceE=IndicatorName+"-NOL-TPPriceE";
string NewOrderLinesTPMoney=IndicatorName+"-NOL-TPMoney";
string NewOrderLinesTPMoneyE=IndicatorName+"-NOL-TPMoneyE";
string NewOrderLinesSLMoney=IndicatorName+"-NOL-SLMoney";
string NewOrderLinesSLMoneyE=IndicatorName+"-NOL-SLMoneyE";

string NewOrderLinesRiskIntro=IndicatorName+"-NOL-RiskIntro";
string NewOrderLinesRiskPerc=IndicatorName+"-NOL-RiskPerc";
string NewOrderLinesRiskPercE=IndicatorName+"-NOL-RiskPercE";
string NewOrderLinesRiskAmount=IndicatorName+"-NOL-RiskAmount";
string NewOrderLinesRiskAmountE=IndicatorName+"-NOL-RiskAmountE";
string NewOrderLinesRiskBase=IndicatorName+"-NOL-RiskBase";
string NewOrderLinesRiskBaseE=IndicatorName+"-NOL-RiskBaseE";
string NewOrderLinesRiskRewardRatio=IndicatorName+"-NOL-RRRatio";
string NewOrderLinesRiskRewardRatioE=IndicatorName+"-NOL-RRRatioE";

string NewOrderLinesURL=IndicatorName+"-NOL-URL";


int NewOrderLinesMonoX=208*PanelSizeMultiplier;
int NewOrderLinesDoubleX=103*PanelSizeMultiplier;
int NewOrderLinesTripleX=68*PanelSizeMultiplier;
int NewOrderLinesLabelY=20*PanelSizeMultiplier;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowNewOrderLines()
  {
   NewOrderLinesMonoX=208*PanelSizeMultiplier;
   NewOrderLinesDoubleX=103*PanelSizeMultiplier;
   NewOrderLinesTripleX=68*PanelSizeMultiplier;
   NewOrderLinesLabelY=20*PanelSizeMultiplier;
   NewOrderLinesPanelIsOpen=true;

   UpdateValues();
   UpdateLinesLabels();

   int NewOrderLinesXoff=Xoff;
   int NewOrderLinesYoff=Yoff+PanelMovY+2*4;
   int NewOrderLinesX=NewOrderLinesMonoX+2+2;
   int NewOrderLinesY=(NewOrderLinesLabelY+2)*11+2;

   string TextSide="";
   string TextType="";
   string TextBuyButton="";
   string TextSellButton="";
   string TextLotSize="";
   string TextPositionSizeTip="";
   string TextSLType="";
   string TextSLPrice="";
   string TextTPPrice="";
   string TextSLPts="";
   string TextTPPts="";
   string TextSLPriceE="";
   string TextTPPriceE="";
   string TextSLPtsE="";
   string TextTPPtsE="";
   string TextPendingOpenPrice="";
   string TextPendingOpenPriceE="";
   string TextPositionSize="";
   string TextRecSize="";
   string TextSLMoneyE="";
   string TextTPMoneyE="";
   string TextRiskAmountE="";
   string TextRiskBaseE="";
   string TextRiskPercE="";
   string TextRRRatio="";
   int j=0;


   TextPendingOpenPrice="OPEN PRICE";
   TextSLPrice="SL PRICE";
   TextTPPrice="TP PRICE";
   TextSLPts="SL POINTS";
   TextTPPts="TP POINTS";
   TextSLPriceE=DoubleToString(CurrSLPrice,Digits);
   TextTPPriceE=DoubleToString(CurrTPPrice,Digits);
   TextSLPtsE=DoubleToString(CurrSLPts,0);
   TextTPPtsE=DoubleToString(CurrTPPts,0);
   TextRRRatio="";
   TextPendingOpenPriceE=DoubleToString(CurrOpenPrice,Digits);
   if(CurrSLPtsOrPrice==ByPrice)
      TextSLType="SL AND TP BY PRICE";
   if(CurrSLPtsOrPrice==ByPts)
      TextSLType="SL AND TP BY POINTS";
   if(CurrLinesSide==LINE_ORDER_BUY)
      TextSide="BUY";
   if(CurrLinesSide==LINE_ORDER_SELL)
      TextSide="SELL";
   if(CurrLinesType==LINE_ORDER_LIMIT)
      TextType="LIMIT";
   if(CurrLinesType==LINE_ORDER_STOP)
      TextType="STOP";
   if(CurrLinesType==LINE_ORDER_MARKET)
      TextType="MARKET";
   if(CurrLinesType==LINE_ORDER_MARKET)
     {
      CurrMarketPending=Market;
     }
   else
     {
      CurrMarketPending=Pending;
     }
   double CurrRecommendedSize=RecommendedSize();
   if(CurrRecommendedSize>0)
      TextRecSize="RECOMMENDED SIZE (LOTS) : "+DoubleToStr(CurrRecommendedSize,2);
   else
      TextRecSize="RECOMMENDED SIZE (LOTS) : N/A";
   TextPositionSize="POSITION SIZE (LOTS)";
   TextPositionSizeTip="Position Size In Lots";
   TextLotSize=DoubleToString(CurrLotSize,2);
   TextRiskPercE=DoubleToString(CurrRiskPerc,2)+" %";
   if(CurrRiskBase==RISK_BALANCE)
      TextRiskBaseE="BALANCE";
   if(CurrRiskBase==RISK_EQUITY)
      TextRiskBaseE="EQUITY";
   if(CurrRiskBase==RISK_FREEMARGIN)
      TextRiskBaseE="FREE MARGIN";

   UpdateRiskAmount();
   TextRiskAmountE=DoubleToString(CurrRiskAmount,2)+" "+AccountCurrency();

   if(CurrSLPts>0)
      TextSLMoneyE=DoubleToStr(CurrSLAmount,2)+" "+AccountCurrency();
   else
      TextSLMoneyE="N/A";
   if(CurrTPPts>0)
      TextTPMoneyE=DoubleToStr(CurrTPAmount,2)+" "+AccountCurrency();
   else
      TextTPMoneyE="N/A";

   UpdateRRRatio();
   if(CurrRRRatio>0)
      TextRRRatio="1 / "+DoubleToString(CurrRRRatio,2);
   else
      TextRRRatio="N/A";
   ObjectCreate(0,NewOrderLinesBase,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSet(NewOrderLinesBase,OBJPROP_XDISTANCE,NewOrderLinesXoff);
   ObjectSet(NewOrderLinesBase,OBJPROP_YDISTANCE,NewOrderLinesYoff);
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_XSIZE,NewOrderLinesX);
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_YSIZE,NewOrderLinesY);
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_BGCOLOR,White);
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSet(NewOrderLinesBase,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_COLOR,clrBlack);

   ObjectCreate(0,NewOrderLinesSide,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesSide,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
   ObjectSet(NewOrderLinesSide,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_XSIZE,NewOrderLinesDoubleX);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_READONLY,true);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesSide,OBJPROP_TOOLTIP,"Click To Change");
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesSide,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesSide,OBJPROP_TEXT,TextSide);
   ObjectSet(NewOrderLinesSide,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_BGCOLOR,clrBlue);
   ObjectSetInteger(0,NewOrderLinesSide,OBJPROP_BORDER_COLOR,clrBlack);

   ObjectCreate(0,NewOrderLinesOrderType,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesOrderType,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
   ObjectSet(NewOrderLinesOrderType,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_XSIZE,NewOrderLinesDoubleX);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_READONLY,true);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesOrderType,OBJPROP_TOOLTIP,"Click To Change");
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesOrderType,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesOrderType,OBJPROP_TEXT,TextType);
   ObjectSet(NewOrderLinesOrderType,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_BGCOLOR,clrRed);
   ObjectSetInteger(0,NewOrderLinesOrderType,OBJPROP_BORDER_COLOR,clrBlack);
   j++;

   if(CurrLinesType!=LINE_ORDER_MARKET)
     {

      ObjectCreate(0,NewOrderLinesPendingOpenPrice,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesPendingOpenPrice,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesPendingOpenPrice,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesPendingOpenPrice,OBJPROP_TOOLTIP,"Start Price - Click To Change");
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesPendingOpenPrice,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesPendingOpenPrice,OBJPROP_TEXT,TextPendingOpenPrice);
      ObjectSet(NewOrderLinesPendingOpenPrice,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPrice,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesPendingOpenPriceE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesPendingOpenPriceE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesPendingOpenPriceE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_READONLY,false);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesPendingOpenPriceE,OBJPROP_TOOLTIP,"Start Price");
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesPendingOpenPriceE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesPendingOpenPriceE,OBJPROP_TEXT,TextPendingOpenPriceE);
      ObjectSet(NewOrderLinesPendingOpenPriceE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesPendingOpenPriceE,OBJPROP_COLOR,clrBlack);
      j++;

     }

   ObjectCreate(0,NewOrderLinesPositionSize,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesPositionSize,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
   ObjectSet(NewOrderLinesPositionSize,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_XSIZE,NewOrderLinesMonoX);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_READONLY,true);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesPositionSize,OBJPROP_TOOLTIP,TextPositionSizeTip);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesPositionSize,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesPositionSize,OBJPROP_TEXT,TextPositionSize);
   ObjectSet(NewOrderLinesPositionSize,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesPositionSize,OBJPROP_COLOR,clrBlack);
   j++;

   ObjectCreate(0,NewOrderLinesLotMinus,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesLotMinus,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
   ObjectSet(NewOrderLinesLotMinus,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_XSIZE,NewOrderLinesTripleX);
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_READONLY,true);
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesLotMinus,OBJPROP_TOOLTIP,"Decrease Lot Size");
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesLotMinus,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesLotMinus,OBJPROP_TEXT,"-");
   ObjectSet(NewOrderLinesLotMinus,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesLotMinus,OBJPROP_COLOR,clrBlack);

   ObjectCreate(0,NewOrderLinesLotSize,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesLotSize,OBJPROP_XDISTANCE,NewOrderLinesXoff+2+NewOrderLinesTripleX+2);
   ObjectSet(NewOrderLinesLotSize,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_XSIZE,NewOrderLinesTripleX);
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_READONLY,false);
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesLotSize,OBJPROP_TOOLTIP,"Lot Size");
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesLotSize,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesLotSize,OBJPROP_TEXT,TextLotSize);
   ObjectSet(NewOrderLinesLotSize,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesLotSize,OBJPROP_COLOR,clrBlack);

   ObjectCreate(0,NewOrderLinesLotPlus,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesLotPlus,OBJPROP_XDISTANCE,NewOrderLinesXoff+2+(NewOrderLinesTripleX+2)*2);
   ObjectSet(NewOrderLinesLotPlus,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_XSIZE,NewOrderLinesTripleX);
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_READONLY,true);
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesLotPlus,OBJPROP_TOOLTIP,"Increase Lot Size");
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesLotPlus,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesLotPlus,OBJPROP_TEXT,"+");
   ObjectSet(NewOrderLinesLotPlus,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesLotPlus,OBJPROP_COLOR,clrBlack);
   j++;

   ObjectCreate(0,NewOrderLinesRecommendedSize,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesRecommendedSize,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
   ObjectSet(NewOrderLinesRecommendedSize,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_XSIZE,NewOrderLinesMonoX);
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_READONLY,true);
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesRecommendedSize,OBJPROP_TOOLTIP,"Recommended Position Size - Click to copy to Position Size");
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesRecommendedSize,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesRecommendedSize,OBJPROP_TEXT,TextRecSize);
   ObjectSet(NewOrderLinesRecommendedSize,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesRecommendedSize,OBJPROP_COLOR,clrBlack);
   j++;

   ObjectCreate(0,NewOrderLinesTargetIntro,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesTargetIntro,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
   ObjectSet(NewOrderLinesTargetIntro,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_XSIZE,NewOrderLinesMonoX);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_READONLY,true);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesTargetIntro,OBJPROP_TOOLTIP,"Stop Loss And Take Profit Mode - Click To Change");
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesTargetIntro,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesTargetIntro,OBJPROP_TEXT,TextSLType);
   ObjectSet(NewOrderLinesTargetIntro,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_COLOR,clrNavy);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_BGCOLOR,clrKhaki);
   ObjectSetInteger(0,NewOrderLinesTargetIntro,OBJPROP_BORDER_COLOR,clrBlack);
   j++;

   if(ShowSLTPPts)
     {
      ObjectCreate(0,NewOrderLinesSLPts,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesSLPts,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesSLPts,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesSLPts,OBJPROP_TOOLTIP,"Stop Loss in Points");
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesSLPts,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesSLPts,OBJPROP_TEXT,TextSLPts);
      ObjectSet(NewOrderLinesSLPts,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesSLPts,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesSLPtsE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesSLPtsE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesSLPtsE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_HIDDEN,true);
      if(CurrSLPtsOrPrice==ByPts)
         ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_READONLY,false);
      if(CurrSLPtsOrPrice==ByPrice)
         ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesSLPtsE,OBJPROP_TOOLTIP,"Stop Loss in Points");
      ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesSLPtsE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesSLPtsE,OBJPROP_TEXT,TextSLPtsE);
      ObjectSet(NewOrderLinesSLPtsE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesSLPtsE,OBJPROP_COLOR,clrBlack);
      j++;
     }

   if(ShowSLTPPrice)
     {
      ObjectCreate(0,NewOrderLinesSLPrice,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesSLPrice,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesSLPrice,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesSLPrice,OBJPROP_TOOLTIP,"Stop Loss Price");
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesSLPrice,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesSLPrice,OBJPROP_TEXT,TextSLPrice);
      ObjectSet(NewOrderLinesSLPrice,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesSLPrice,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesSLPriceE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesSLPriceE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesSLPriceE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_HIDDEN,true);
      if(CurrSLPtsOrPrice==ByPrice)
         ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_READONLY,false);
      if(CurrSLPtsOrPrice==ByPts)
         ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesSLPriceE,OBJPROP_TOOLTIP,"Stop Loss Price");
      ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesSLPriceE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesSLPriceE,OBJPROP_TEXT,TextSLPriceE);
      ObjectSet(NewOrderLinesSLPriceE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesSLPriceE,OBJPROP_COLOR,clrBlack);
      j++;
     }

   if(ShowSLTPAmount)
     {
      ObjectCreate(0,NewOrderLinesSLMoney,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesSLMoney,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesSLMoney,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesSLMoney,OBJPROP_TOOLTIP,"Possible Stop Loss Amount In Your Account Currency");
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesSLMoney,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesSLMoney,OBJPROP_TEXT,"POSSIBLE LOSS");
      ObjectSet(NewOrderLinesSLMoney,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesSLMoney,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesSLMoneyE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesSLMoneyE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesSLMoneyE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesSLMoneyE,OBJPROP_TOOLTIP,"Possible Stop Loss Amount In Your Account Currency");
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesSLMoneyE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesSLMoneyE,OBJPROP_TEXT,TextSLMoneyE);
      ObjectSet(NewOrderLinesSLMoneyE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_COLOR,clrWhite);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_BGCOLOR,clrMaroon);
      ObjectSetInteger(0,NewOrderLinesSLMoneyE,OBJPROP_BORDER_COLOR,clrBlack);
      j++;
     }

   if(ShowSLTPPts)
     {
      ObjectCreate(0,NewOrderLinesTPPts,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesTPPts,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesTPPts,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesTPPts,OBJPROP_TOOLTIP,"Take Profit in Points");
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesTPPts,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesTPPts,OBJPROP_TEXT,TextTPPts);
      ObjectSet(NewOrderLinesTPPts,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesTPPts,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesTPPtsE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesTPPtsE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesTPPtsE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_HIDDEN,true);
      if(CurrSLPtsOrPrice==ByPts)
         ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_READONLY,false);
      if(CurrSLPtsOrPrice==ByPrice)
         ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesTPPtsE,OBJPROP_TOOLTIP,"Take Profit in Points");
      ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesTPPtsE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesTPPtsE,OBJPROP_TEXT,TextTPPtsE);
      ObjectSet(NewOrderLinesTPPtsE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesTPPtsE,OBJPROP_COLOR,clrBlack);
      j++;
     }

   if(ShowSLTPPrice)
     {
      ObjectCreate(0,NewOrderLinesTPPrice,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesTPPrice,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesTPPrice,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesTPPrice,OBJPROP_TOOLTIP,"Take Profit Price");
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesTPPrice,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesTPPrice,OBJPROP_TEXT,TextTPPrice);
      ObjectSet(NewOrderLinesTPPrice,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesTPPrice,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesTPPriceE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesTPPriceE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesTPPriceE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_HIDDEN,true);
      if(CurrSLPtsOrPrice==ByPts)
         ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_READONLY,true);
      if(CurrSLPtsOrPrice==ByPrice)
         ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_READONLY,false);
      ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesTPPriceE,OBJPROP_TOOLTIP,"Take Profit Price");
      ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesTPPriceE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesTPPriceE,OBJPROP_TEXT,TextTPPriceE);
      ObjectSet(NewOrderLinesTPPriceE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesTPPriceE,OBJPROP_COLOR,clrBlack);
      j++;
     }

   if(ShowSLTPAmount)
     {
      ObjectCreate(0,NewOrderLinesTPMoney,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesTPMoney,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesTPMoney,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesTPMoney,OBJPROP_TOOLTIP,"Possible Take Profit Amount In Your Account Currency");
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesTPMoney,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesTPMoney,OBJPROP_TEXT,"POSSIBLE PROFIT");
      ObjectSet(NewOrderLinesTPMoney,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesTPMoney,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesTPMoneyE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesTPMoneyE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesTPMoneyE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesTPMoneyE,OBJPROP_TOOLTIP,"Possible Take Profit Amount In Your Account Currency");
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesTPMoneyE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesTPMoneyE,OBJPROP_TEXT,TextTPMoneyE);
      ObjectSet(NewOrderLinesTPMoneyE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_COLOR,clrWhite);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_BGCOLOR,clrForestGreen);
      ObjectSetInteger(0,NewOrderLinesTPMoneyE,OBJPROP_BORDER_COLOR,clrBlack);
      j++;
     }

   ObjectCreate(0,NewOrderLinesRiskIntro,OBJ_EDIT,0,0,0);
   ObjectSet(NewOrderLinesRiskIntro,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
   ObjectSet(NewOrderLinesRiskIntro,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_XSIZE,NewOrderLinesMonoX);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_YSIZE,NewOrderLinesLabelY);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_STATE,false);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_READONLY,true);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_FONTSIZE,NOFontSize);
   ObjectSetString(0,NewOrderLinesRiskIntro,OBJPROP_TOOLTIP,"Risk Parameters ForLot Calculation");
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,NewOrderLinesRiskIntro,OBJPROP_FONT,NOFont);
   ObjectSetString(0,NewOrderLinesRiskIntro,OBJPROP_TEXT,"RISK PARAMETERS");
   ObjectSet(NewOrderLinesRiskIntro,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_COLOR,clrNavy);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_BGCOLOR,clrKhaki);
   ObjectSetInteger(0,NewOrderLinesRiskIntro,OBJPROP_BORDER_COLOR,clrBlack);
   j++;

   if(ShowRiskBase)
     {
      ObjectCreate(0,NewOrderLinesRiskBase,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesRiskBase,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesRiskBase,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesRiskBase,OBJPROP_TOOLTIP,"Risk Calculation Base");
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesRiskBase,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesRiskBase,OBJPROP_TEXT,"RISK BASE");
      ObjectSet(NewOrderLinesRiskBase,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesRiskBase,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesRiskBaseE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesRiskBaseE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesRiskBaseE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesRiskBaseE,OBJPROP_TOOLTIP,"Risk Calculation Base - Click To Change");
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesRiskBaseE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesRiskBaseE,OBJPROP_TEXT,TextRiskBaseE);
      ObjectSet(NewOrderLinesRiskBaseE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_COLOR,clrWhite);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_BGCOLOR,clrBlue);
      ObjectSetInteger(0,NewOrderLinesRiskBaseE,OBJPROP_BORDER_COLOR,clrBlack);
      j++;
     }

   if(ShowRiskPerc)
     {
      ObjectCreate(0,NewOrderLinesRiskPerc,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesRiskPerc,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesRiskPerc,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesRiskPerc,OBJPROP_TOOLTIP,"Risk Calculation Precentage");
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesRiskPerc,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesRiskPerc,OBJPROP_TEXT,"RISK %");
      ObjectSet(NewOrderLinesRiskPerc,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesRiskPerc,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesRiskPercE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesRiskPercE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesRiskPercE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_READONLY,false);
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesRiskPercE,OBJPROP_TOOLTIP,"Risk Calculation Percentage - Click To Change");
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesRiskPercE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesRiskPercE,OBJPROP_TEXT,TextRiskPercE);
      ObjectSet(NewOrderLinesRiskPercE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesRiskPercE,OBJPROP_COLOR,clrBlack);
      j++;
     }

   if(ShowRiskAmount)
     {
      ObjectCreate(0,NewOrderLinesRiskAmount,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesRiskAmount,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesRiskAmount,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesRiskAmount,OBJPROP_TOOLTIP,"Risk Amount In Your Account Currency");
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesRiskAmount,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesRiskAmount,OBJPROP_TEXT,"RISK AMOUNT");
      ObjectSet(NewOrderLinesRiskAmount,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesRiskAmount,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesRiskAmountE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesRiskAmountE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesRiskAmountE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_READONLY,false);
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesRiskAmountE,OBJPROP_TOOLTIP,"Risk Amount In Your Account Currency - Click To Change");
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesRiskAmountE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesRiskAmountE,OBJPROP_TEXT,TextRiskAmountE);
      ObjectSet(NewOrderLinesRiskAmountE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesRiskAmountE,OBJPROP_COLOR,clrBlack);
      j++;
     }

   if(ShowRRR)
     {
      ObjectCreate(0,NewOrderLinesRiskRewardRatio,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesRiskRewardRatio,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesRiskRewardRatio,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesRiskRewardRatio,OBJPROP_TOOLTIP,"Risk Reward Ratio Calculated");
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesRiskRewardRatio,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesRiskRewardRatio,OBJPROP_TEXT,"R/R RATIO");
      ObjectSet(NewOrderLinesRiskRewardRatio,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatio,OBJPROP_COLOR,clrBlack);

      ObjectCreate(0,NewOrderLinesRiskRewardRatioE,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesRiskRewardRatioE,OBJPROP_XDISTANCE,NewOrderLinesXoff+(NewOrderLinesDoubleX+2)+2);
      ObjectSet(NewOrderLinesRiskRewardRatioE,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_XSIZE,NewOrderLinesDoubleX);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesRiskRewardRatioE,OBJPROP_TOOLTIP,"Risk Reward Ratio Calculated");
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesRiskRewardRatioE,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesRiskRewardRatioE,OBJPROP_TEXT,TextRRRatio);
      ObjectSet(NewOrderLinesRiskRewardRatioE,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesRiskRewardRatioE,OBJPROP_COLOR,clrBlack);
      j++;
     }

   if(ShowURL)
     {
      ObjectCreate(0,NewOrderLinesURL,OBJ_EDIT,0,0,0);
      ObjectSet(NewOrderLinesURL,OBJPROP_XDISTANCE,NewOrderLinesXoff+2);
      ObjectSet(NewOrderLinesURL,OBJPROP_YDISTANCE,NewOrderLinesYoff+2+(NewOrderLinesLabelY+1)*j);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_XSIZE,NewOrderLinesMonoX);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_YSIZE,NewOrderLinesLabelY);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_STATE,false);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_READONLY,true);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_FONTSIZE,NOFontSize);
      ObjectSetString(0,NewOrderLinesURL,OBJPROP_TOOLTIP,"Visit Us");
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetString(0,NewOrderLinesURL,OBJPROP_FONT,NOFont);
      ObjectSetString(0,NewOrderLinesURL,OBJPROP_TEXT,"EarnForex.com");
      ObjectSet(NewOrderLinesURL,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_COLOR,clrNavy);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_BGCOLOR,clrKhaki);
      ObjectSetInteger(0,NewOrderLinesURL,OBJPROP_BORDER_COLOR,clrBlack);
      j++;
     }

   NewOrderLinesY=(NewOrderLinesLabelY+1)*j+3;
   ObjectSetInteger(0,NewOrderLinesBase,OBJPROP_YSIZE,NewOrderLinesY);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseNewOrderLines()
  {
   int Window=0;
   for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
     {
      if((StringFind(ObjectName(i),IndicatorName+"-NOL-",0)>=0) && !(StringFind(ObjectName(i),IndicatorName+"-NOL-H-",0)>=0))
        {
         ObjectDelete(ObjectName(i));
        }
     }
   NewOrderLinesPanelIsOpen=false;
   CurrSLPrice=0;
   CurrTPPrice=0;
   CurrSLPts=0;
   CurrTPPts=0;
   DeleteNewOrderLine(LINE_ALL);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeLinesRiskBase()
  {
   if(CurrRiskBase==RISK_BALANCE)
     {
      CurrRiskBase=RISK_EQUITY;
      ShowNewOrderLines();
      return;
     }
   if(CurrRiskBase==RISK_EQUITY)
     {
      CurrRiskBase=RISK_FREEMARGIN;
      ShowNewOrderLines();
      return;
     }
   if(CurrRiskBase==RISK_FREEMARGIN)
     {
      CurrRiskBase=RISK_BALANCE;
      ShowNewOrderLines();
      return;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeLinesOrderSide()
  {
   if(CurrLinesSide==LINE_ORDER_BUY)
     {
      CurrLinesSide=LINE_ORDER_SELL;
      CloseNewOrderLines();
      ShowNewOrderLines();
      return;
     }
   if(CurrLinesSide==LINE_ORDER_SELL)
     {
      CurrLinesSide=LINE_ORDER_BUY;
      CloseNewOrderLines();
      ShowNewOrderLines();
      return;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeLinesOrderType()
  {
   if(CurrLinesType==LINE_ORDER_MARKET)
     {
      CurrLinesType=LINE_ORDER_STOP;
      CurrOpenPrice=Close[0];
      CloseNewOrderLines();
      ShowNewOrderLines();
      ChangeSLPrice();
      ChangeTPPrice();
      CreateNewOrderLine(LINE_OPEN_PRICE);
      return;
     }
   if(CurrLinesType==LINE_ORDER_STOP)
     {
      CurrLinesType=LINE_ORDER_LIMIT;
      CloseNewOrderLines();
      CurrOpenPrice=Close[0];
      ShowNewOrderLines();
      ChangeSLPrice();
      ChangeTPPrice();
      CreateNewOrderLine(LINE_OPEN_PRICE);
      return;
     }
   if(CurrLinesType==LINE_ORDER_LIMIT)
     {
      CurrLinesType=LINE_ORDER_MARKET;
      DeleteNewOrderLine(LINE_OPEN_PRICE);
      CurrOpenPrice=Close[0];
      CloseNewOrderLines();
      ShowNewOrderLines();
      ChangeSLPrice();
      ChangeTPPrice();
      return;
     }
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChangeSLPtsPrice()
  {
   if(CurrSLPtsOrPrice==ByPrice)
     {
      CurrSLPtsOrPrice=ByPts;
      CurrSLPrice=0;
      CurrSLPts=0;
      CurrTPPrice=0;
      CurrTPPts=0;
      DeleteNewOrderLine(LINE_SL_PRICE);
      DeleteNewOrderLine(LINE_TP_PRICE);
      ShowNewOrderLines();
      return;
     }
   if(CurrSLPtsOrPrice==ByPts)
     {
      CurrSLPtsOrPrice=ByPrice;
      CurrSLPrice=0;
      CurrSLPts=0;
      CurrTPPrice=0;
      CurrTPPts=0;
      DeleteNewOrderLine(LINE_SL_PRICE);
      DeleteNewOrderLine(LINE_TP_PRICE);
      ShowNewOrderLines();
      return;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteNewOrderLine(ENUM_LINE_TYPE Type)
  {
   string TextType="";
   if(Type==LINE_ALL)
     {
      DeleteNewOrderLine(LINE_OPEN_PRICE);
      DeleteNewOrderLine(LINE_TP_PRICE);
      DeleteNewOrderLine(LINE_SL_PRICE);
     }
   if(Type==LINE_OPEN_PRICE)
      TextType="OPEN";
   if(Type==LINE_TP_PRICE)
      TextType="TP";
   if(Type==LINE_SL_PRICE)
      TextType="SL";
   int Window=0;
   for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
     {
      if((StringFind(ObjectName(i),IndicatorName+"-NOL-H-"+TextType,0)>=0))
        {
         ObjectDelete(ObjectName(i));
        }
     }
   DeleteLineLabels();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateLinesDeleted(string LineName)
  {
   if(NewOrderLinesPanelIsOpen)
     {
      if(LineName==LineNameOpen)
        {
         CurrLinesType=LINE_ORDER_MARKET;
         ShowNewOrderLines();
        }
      if(LineName==LineNameSL)
        {
         CurrSLPrice=0;
         ShowNewOrderLines();
        }
      if(LineName==LineNameTP)
        {
         CurrTPPrice=0;
         ShowNewOrderLines();
        }
      UpdateLinesLabels();
     }
  }


string LineNameOpen=IndicatorName+"-NOL-H-OPEN";
string LineNameSL=IndicatorName+"-NOL-H-SL";
string LineNameTP=IndicatorName+"-NOL-H-TP";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateNewOrderLine(ENUM_LINE_TYPE Type)
  {
   string TextType="";
   color LineColor=clrNONE;
   double LinePrice=0;
   string LineName="";
   if(Type==LINE_OPEN_PRICE)
     {
      LineName=LineNameOpen;
      LineColor=LineOpenPriceColor;
      LinePrice=Close[0];
      TextType="OPEN-PRICE";
     }
   if(Type==LINE_TP_PRICE)
     {
      LineName=LineNameTP;
      LineColor=LineTPPriceColor;
      LinePrice=CurrTPPrice;
      TextType="TP-PRICE";
     }
   if(Type==LINE_SL_PRICE)
     {
      LineName=LineNameSL;
      LineColor=LineSLPriceColor;
      LinePrice=CurrSLPrice;
      TextType="SL-PRICE";
     }
   int Window=0;
   for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
     {
      if((StringFind(ObjectName(i),LineName,0)>=0))
        {
         return;
        }
     }
   ObjectCreate(0,LineName,OBJ_HLINE,0,0,LinePrice);
   ObjectSetString(0,LineName,OBJPROP_TEXT,"LINE-"+TextType);
   ObjectSet(LineName,OBJPROP_COLOR,LineColor);
   ObjectSet(LineName,OBJPROP_STYLE,LineStyle);
   ObjectSet(LineName,OBJPROP_BACK,false);
   if(CurrSLPtsOrPrice==ByPrice || LineName==LineNameOpen)
      ObjectSet(LineName,OBJPROP_SELECTABLE,true);
   if(CurrSLPtsOrPrice==ByPts && LineName!=LineNameOpen)
      ObjectSet(LineName,OBJPROP_SELECTABLE,false);
   ObjectSet(LineName,OBJPROP_HIDDEN,false);
   UpdateLinesLabels();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClickNewOrderLinesSLPrice()
  {
   bool LineExist=false;
   string LineName=LineNameSL;
   int Window=0;
   for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
     {
      if((StringFind(ObjectName(i),LineName,0)>=0))
        {
         LineExist=true;
        }
     }
   if(LineExist)
     {
      CurrSLPrice=0;
      CurrSLPts=0;
      ObjectDelete(0,LineName);
      ShowNewOrderLines();
     }
   else
     {
      if(CurrLinesSide==LINE_ORDER_BUY)
        {
         CurrSLPrice=Low[0];
        }
      if(CurrLinesSide==LINE_ORDER_SELL)
        {
         CurrSLPrice=High[0];
        }
      CreateNewOrderLine(LINE_SL_PRICE);
      ShowNewOrderLines();
      ChangeSLPrice();
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClickNewOrderLinesTPPrice()
  {
   bool LineExist=false;
   string LineName=LineNameTP;
   int Window=0;
   for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
     {
      if((StringFind(ObjectName(i),LineName,0)>=0))
        {
         LineExist=true;
        }
     }
   if(LineExist)
     {
      CurrTPPrice=0;
      CurrTPPts=0;
      ObjectDelete(0,LineName);
      ShowNewOrderLines();
     }
   else
     {
      if(CurrLinesSide==LINE_ORDER_BUY)
        {
         CurrTPPrice=High[0];
        }
      if(CurrLinesSide==LINE_ORDER_SELL)
        {
         CurrTPPrice=Low[0];
        }
      CreateNewOrderLine(LINE_TP_PRICE);
      ShowNewOrderLines();
      ChangeTPPrice();
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdatePriceByLine(string LineName)
  {
   if(NewOrderLinesPanelIsOpen)
     {
      if(LineName==LineNameOpen)
        {
         CurrOpenPrice=NormalizeDouble(ObjectGetDouble(0,LineName,OBJPROP_PRICE,0),Digits);
         ShowNewOrderLines();
         ChangeSLPrice();
         ChangeTPPrice();
        }
      if(LineName==LineNameSL)
        {
         CurrSLPrice=NormalizeDouble(ObjectGetDouble(0,LineName,OBJPROP_PRICE,0),Digits);
         ShowNewOrderLines();
         ChangeSLPrice();
         ChangeTPPrice();
        }
      if(LineName==LineNameTP)
        {
         CurrTPPrice=NormalizeDouble(ObjectGetDouble(0,LineName,OBJPROP_PRICE,0),Digits);
         ShowNewOrderLines();
         ChangeSLPrice();
         ChangeTPPrice();
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateLineByPrice(string LineName)
  {
   if(LineName==LineNameOpen)
     {
      bool LineExist=false;
      int Window=0;
      for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
        {
         if((StringFind(ObjectName(i),LineName,0)>=0))
           {
            LineExist=true;
            break;
           }
        }
      if(LineExist)
         ObjectSetDouble(0,LineName,OBJPROP_PRICE,CurrOpenPrice);
      else
         CreateNewOrderLine(LINE_OPEN_PRICE);
     }
   if(LineName==LineNameSL)
     {
      bool LineExist=false;
      int Window=0;
      for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
        {
         if((StringFind(ObjectName(i),LineName,0)>=0))
           {
            LineExist=true;
            break;
           }
        }
      if(LineExist)
         ObjectSetDouble(0,LineName,OBJPROP_PRICE,CurrSLPrice);
      else
         CreateNewOrderLine(LINE_SL_PRICE);
     }
   if(LineName==LineNameTP)
     {
      bool LineExist=false;
      int Window=0;
      for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
        {
         if((StringFind(ObjectName(i),LineName,0)>=0))
           {
            LineExist=true;
            break;
           }
        }
      if(LineExist)
         ObjectSetDouble(0,LineName,OBJPROP_PRICE,CurrTPPrice);
      else
         CreateNewOrderLine(LINE_TP_PRICE);
     }
   UpdateLinesLabels();
  }


string LineLabelNameOpen=IndicatorName+"-NOL-HLAB-OPEN";
string LineLabelNameSL=IndicatorName+"-NOL-HLAB-SL";
string LineLabelNameTP=IndicatorName+"-NOL-HLAB-TP";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateLinesLabels()
  {
   DeleteLineLabels();
   int XLab=200*PanelSizeMultiplier;
   int YLab=20*PanelSizeMultiplier;
   double Ratio=0;
   double LossPts=CurrSLPts;
   double ProfitPts=CurrTPPts;
   double LossCurrency=CurrSLAmount;
   double ProfitCurrency=CurrTPAmount;
   double OpenPrice=CurrOpenPrice;
   string OpenText="";
   string SLText="";
   string TPText="";
   string OpenTextTip="";
   string SLTextTip="";
   string TPTextTip="";
   if(LossPts>0 || (LossPts==0 && CurrSLPrice!=0))
     {
      SLText="SL - "+DoubleToString(LossPts,0)+" Pts - "+DoubleToString(LossCurrency,2)+" "+AccountCurrency();
      SLTextTip="Possible Loss Of - "+DoubleToString(LossPts,0)+" Points - "+DoubleToString(LossCurrency,2)+" "+AccountCurrency();
     }
   if(ProfitPts>0 || (ProfitPts==0 && CurrTPPrice!=0))
     {
      TPText="TP - "+DoubleToString(ProfitPts,0)+" Pts - "+DoubleToString(ProfitCurrency,2)+" "+AccountCurrency();
      TPTextTip="Possible Profit Of - "+DoubleToString(ProfitPts,0)+" Points - "+DoubleToString(ProfitCurrency,2)+" "+AccountCurrency();
     }
   if(LossPts>0 && ProfitPts>0)
     {
      Ratio=NormalizeDouble(CurrRRRatio,2);
      OpenText="R/R RATIO : 1 / "+DoubleToString(Ratio,2);
      OpenTextTip="This Trade Has A Risk Reward Ratio Of 1 To "+DoubleToString(Ratio,2);
     }
   if(LossPts<0)
     {
      SLText="SL NOT VALID";
      SLTextTip="The Stop Loss Value Is In A Wrong Position, Please Check";
     }
   if(ProfitPts<0)
     {
      TPText="TP NOT VALID";
      TPTextTip="The Take Profit Value Is In A Wrong Position, Please Check";
     }
   if(CurrRRRatio!=0)
     {
      int XStart=220*PanelSizeMultiplier;
      int YStart=0;
      ChartTimePriceToXY(0,0,Time[0],OpenPrice,XStart,YStart);
      XStart=220*PanelSizeMultiplier;
      DrawEdit(LineLabelNameOpen,
               XStart,
               YStart,
               XLab,
               YLab,
               true,
               8,
               OpenTextTip,
               ALIGN_CENTER,
               "Consolas",
               OpenText,
               false,
               LineOpenPriceColor);
      ObjectSetInteger(0,LineLabelNameOpen,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
     }
   if(LossPts!=0 || (LossPts==0 && CurrSLPrice!=0))
     {
      int XStart=220*PanelSizeMultiplier;
      int YStart=0;
      ChartTimePriceToXY(0,0,Time[0],CurrSLPrice,XStart,YStart);
      XStart=220*PanelSizeMultiplier;
      DrawEdit(LineLabelNameSL,
               XStart,
               YStart,
               XLab,
               YLab,
               true,
               8,
               SLTextTip,
               ALIGN_CENTER,
               "Consolas",
               SLText,
               false,
               LineSLPriceColor);
      ObjectSetInteger(0,LineLabelNameSL,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
     }
   if(ProfitPts!=0 || (ProfitPts==0 && CurrTPPrice!=0))
     {
      int XStart=220*PanelSizeMultiplier;
      int YStart=0;
      ChartTimePriceToXY(0,0,Time[0],CurrTPPrice,XStart,YStart);
      XStart=220*PanelSizeMultiplier;
      DrawEdit(LineLabelNameTP,
               XStart,
               YStart,
               XLab,
               YLab,
               true,
               8,
               TPTextTip,
               ALIGN_CENTER,
               "Consolas",
               TPText,
               false,
               LineTPPriceColor);
      ObjectSetInteger(0,LineLabelNameTP,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteLineLabels()
  {
   int Window=0;
   for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
     {
      if((StringFind(ObjectName(i),IndicatorName+"-NOL-HLAB-",0)>=0))
        {
         ObjectDelete(ObjectName(i));
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateValues()
  {
   if(CurrSLPtsOrPrice==ByPts && (CurrSLPts>0 || CurrTPPts>0))
     {
      if(CurrLinesSide==LINE_ORDER_BUY)
        {
         double OpenPrice=0;
         RefreshRates();
         if(CurrLinesSide==LINE_ORDER_BUY && CurrLinesType==LINE_ORDER_MARKET)
           {
            OpenPrice=Ask;
           }
         if(CurrLinesType!=LINE_ORDER_MARKET)
           {
            OpenPrice=CurrOpenPrice;
           }
         if(CurrSLPts!=0)
           {
            CurrSLPrice=OpenPrice-CurrSLPts*MarketInfo(Symbol(),MODE_TICKSIZE);
            CurrSLAmount=CurrSLPts*TickValue*CurrLotSize;
           }
         if(CurrTPPts!=0)
           {
            CurrTPPrice=OpenPrice+CurrTPPts*Point;
            CurrTPAmount=CurrTPPts*TickValue*CurrLotSize;
           }
        }
      if(CurrLinesSide==LINE_ORDER_SELL)
        {
         double OpenPrice=0;
         RefreshRates();
         if(CurrLinesSide==LINE_ORDER_SELL && CurrLinesType==LINE_ORDER_MARKET)
           {
            OpenPrice=Bid;
           }
         if(CurrLinesType!=LINE_ORDER_MARKET)
           {
            OpenPrice=CurrOpenPrice;
           }
         if(CurrSLPts!=0)
           {
            CurrSLPrice=OpenPrice+CurrSLPts*MarketInfo(Symbol(),MODE_TICKSIZE);
            CurrSLAmount=CurrSLPts*TickValue*CurrLotSize;
           }
         if(CurrTPPts!=0)
           {
            CurrTPPrice=OpenPrice-CurrTPPts*Point;
            CurrTPAmount=CurrTPPts*TickValue*CurrLotSize;
           }
        }
      UpdateLineByPrice(LineNameSL);
      UpdateLineByPrice(LineNameTP);
     }
   if(CurrSLPtsOrPrice==ByPrice && (CurrSLPrice>0 || CurrTPPrice>0))
     {
      if(CurrLinesSide==LINE_ORDER_BUY)
        {
         double OpenPrice=0;
         RefreshRates();
         if(CurrLinesSide==LINE_ORDER_BUY && CurrLinesType==LINE_ORDER_MARKET)
           {
            OpenPrice=Ask;
           }
         if(CurrLinesType!=LINE_ORDER_MARKET)
           {
            OpenPrice=CurrOpenPrice;
           }
         if(CurrSLPrice!=0)
           {
            CurrSLPts=(OpenPrice-CurrSLPrice)/MarketInfo(Symbol(),MODE_TICKSIZE);
            CurrSLAmount=CurrSLPts*TickValue*CurrLotSize;
           }
         if(CurrTPPrice!=0)
           {
            CurrTPPts=(CurrTPPrice-OpenPrice)/Point;
            CurrTPAmount=CurrTPPts*TickValue*CurrLotSize;
           }
        }
      if(CurrLinesSide==LINE_ORDER_SELL)
        {
         double OpenPrice=0;
         RefreshRates();
         if(CurrLinesSide==LINE_ORDER_SELL && CurrLinesType==LINE_ORDER_MARKET)
           {
            OpenPrice=Bid;
           }
         if(CurrLinesType!=LINE_ORDER_MARKET)
           {
            OpenPrice=CurrOpenPrice;
           }
         if(CurrSLPrice!=0)
           {
            CurrSLPts=(CurrSLPrice-OpenPrice)/MarketInfo(Symbol(),MODE_TICKSIZE);
            CurrSLAmount=CurrSLPts*TickValue*CurrLotSize;
           }
         if(CurrTPPrice!=0)
           {
            CurrTPPts=(OpenPrice-CurrTPPrice)/Point;
            CurrTPAmount=CurrTPPts*TickValue*CurrLotSize;
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RecommendedSize()
  {
   double StopLoss=0;
   double Base=0;
   double Lots=0;
   if(CurrRiskBase==RISK_EQUITY)
      Base=AccountEquity();
   if(CurrRiskBase==RISK_BALANCE)
      Base=AccountBalance();
   if(CurrRiskBase==RISK_FREEMARGIN)
      Base=AccountFreeMargin();
   double Points=MarketInfo(Symbol(),MODE_POINT);
   double OpenPrice=0;
   double SLPrice=CurrSLPrice;
   if(CurrMarketPending==Pending)
     {
      OpenPrice=CurrOpenPrice;
      if(SLPrice>0)
         StopLoss=MathAbs(MathRound((OpenPrice-SLPrice)/Points));

     }
   if(CurrMarketPending==Market)
     {
      if(SLPrice>MarketInfo(Symbol(),MODE_ASK) && SLPrice>MarketInfo(Symbol(),MODE_BID))
         OpenPrice=MarketInfo(Symbol(),MODE_BID);
      if(SLPrice<MarketInfo(Symbol(),MODE_ASK) && SLPrice<MarketInfo(Symbol(),MODE_BID))
         OpenPrice=MarketInfo(Symbol(),MODE_ASK);
      if(SLPrice>0)
         StopLoss=MathAbs(MathRound((OpenPrice-SLPrice)/Points));
     }
   if(StopLoss>=MarketInfo(Symbol(),MODE_STOPLEVEL) && StopLoss>0)
      Lots=(Base*CurrRiskPerc/100)/(StopLoss*TickValue);
   return Lots;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateRiskAmount()
  {
   if(CurrRiskBase==RISK_EQUITY)
      CurrRiskAmount=AccountEquity()*CurrRiskPerc/100;
   if(CurrRiskBase==RISK_BALANCE)
      CurrRiskAmount=AccountBalance()*CurrRiskPerc/100;
   if(CurrRiskBase==RISK_FREEMARGIN)
      CurrRiskAmount=AccountFreeMargin()*CurrRiskPerc/100;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateRRRatio()
  {
   if(CurrSLPts>0 && CurrTPPts>0)
      CurrRRRatio=NormalizeDouble(CurrTPPts/CurrSLPts,2);
   else
      CurrRRRatio=0;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CleanChart()
  {
   int Window=0;
   for(int i=ObjectsTotal(ChartID(),Window,-1)-1; i>=0; i--)
     {
      if(StringFind(ObjectName(i),IndicatorName,0)>=0)
        {
         ObjectDelete(ObjectName(i));
        }
     }
  }

//+------------------------------------------------------------------+

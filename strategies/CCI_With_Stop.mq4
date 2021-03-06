//+------------------------------------------------------------------+
//|                                                CCI With Stop.mq4 |
//|                                                   Master-Ukulele |
//|               github.com/Master-Ukulele/Commodity-Channel-Index/ |
//+------------------------------------------------------------------+
#property copyright "Master-Ukulele"
#property link      "github.com/Master-Ukulele/Commodity-Channel-Index/"
#property version   "1.00"
#property strict

extern double     Lots =  0.01;
extern double     ORDER =    1;
extern int        chk =      0;
extern int        flag =     0;

extern bool   g_debug =   true;
extern double g_initStop = 200;
extern double g_breakEven = 20;
extern double g_stepSize =   3;
extern double g_measure =   10;
extern double g_stopMax =  300;
extern double g_profitExtendThreshold = 0.75;
extern double g_profitMax = 0; // close order if profit reaches the pre-defined max value

int doStepStop() {
    int total = OrdersTotal();
    for (int i = 0; i < total; i++) {
        if (OrderSelect(i, SELECT_BY_POS)) {
            if (OrderSymbol() != Symbol()) {
                continue;
            }
            double flag = 0;
            double price = 0; // current price
            double desiredProfit = 0;
            double realProfit = 0;
            double profitModifier = 0;
            double takeProfit = OrderTakeProfit();
            double stopLoss = OrderStopLoss();
            double stepStopTrigger = (g_breakEven + g_initStop) * Point;
            if (OrderType() == OP_BUY) {
                flag = 1;
                price = Bid;
            }    else if (OrderType() == OP_SELL) {
                flag = -1;
                price = Ask;
            } else {
                continue;
            }
            if (takeProfit <= 0) {
                takeProfit = OrderOpenPrice() + flag * (g_breakEven + g_initStop + g_stepSize) * Point;
            }
            if (stopLoss <= 0) {
                stopLoss = OrderOpenPrice() - flag * g_initStop * Point;
            }
            desiredProfit = MathAbs(takeProfit - OrderOpenPrice());
            if (desiredProfit <= Point) {
                continue;
            }
            realProfit = flag * (price - OrderOpenPrice()); // could be a negtive number!
            if (realProfit > 0) {
                if ((realProfit / desiredProfit > g_profitExtendThreshold) || (desiredProfit - realProfit < 2 * g_stepSize * Point)) {
                    // profitModifier is always a positive number
                    profitModifier = MathMax(desiredProfit / g_profitExtendThreshold + g_stepSize * Point, desiredProfit + 2 * g_stepSize * Point);
                }
                if (desiredProfit - stepStopTrigger > 0) {
                    if ((desiredProfit - realProfit > 0) && (realProfit - stepStopTrigger > 0)) {
                        double k = (desiredProfit - realProfit) / (g_measure * Point);
                        stopLoss = price - flag * (k * g_stepSize + g_initStop) * Point;
                        if (flag * (stopLoss - OrderStopLoss()) < 0 || MathAbs(stopLoss - OrderStopLoss()) < g_stepSize * Point) {
                            stopLoss = OrderStopLoss();
                        }
                    }
                }
            }
            stopLoss = NormalizeDouble(stopLoss, Digits);
            if (MathAbs(takeProfit - OrderOpenPrice()) < profitModifier) {
                if (g_profitMax > 0 && profitModifier - g_profitMax * Point > 0) {
                    profitModifier = g_profitMax * Point;
                }
                takeProfit = OrderOpenPrice() + flag * profitModifier;
            }
            takeProfit = NormalizeDouble(takeProfit, Digits);
            if (MathAbs(stopLoss - OrderStopLoss()) >= Point || MathAbs(takeProfit - OrderTakeProfit()) >= Point) {
                Print("order before modify: tk(" + OrderTicket() + "), sl(" + DoubleToStr(OrderStopLoss(), 4) + "), tp(" + DoubleToStr(OrderTakeProfit(), 4) + ")");
                OrderModify(OrderTicket(), OrderOpenPrice(), stopLoss, takeProfit, 0);
            }
        }
    }
    return(0);
}

int validateParams() {
    if (g_initStop < 0 || g_stepSize < 0 || g_measure < 0 || g_breakEven < 0) {
        Alert("g_initStop, g_stepSize, g_measure & g_breakEven can not be negtive.");
        return(-1);
    }
    if (g_measure <= g_stepSize) {
        Alert("g_measure must be greater than g_stepSize.");
        return(-1);
    }
    if (g_profitExtendThreshold <= 0 || g_profitExtendThreshold >= 1) {
        Alert("range of g_extendProfitThreshold is (0, 1).");
        return(-1);
    }
    return(0);
}

int init() {
    doStepStop();
    return(0);
}

int deinit() {
    return(0);
}

//+------------------------------------------------------------------+
//|                     Main Body Function                           |
//+------------------------------------------------------------------+
int start() {
    if (validateParams() == 0) {
        doStepStop();
    }

    int  ticket, total;
    double C1,C2,C3;
    C1=iCCI(Symbol(),0,14,PRICE_TYPICAL,0);
    C2=iCCI(Symbol(),0,14,PRICE_TYPICAL,1);
    C3=iCCI(Symbol(),0,14,PRICE_TYPICAL,2);
   
    total=OrdersTotal();
    if(total<ORDER) {
        if(AccountFreeMargin()<(1000*Lots)) {
            Print("NO MONEY = ", AccountFreeMargin());
            return(0);
        }
     
        {
            chk=1;
            if(flag==0) {
                Print("Ready");
                flag=1;
            }
        }

        if(chk==1) {
        //------------------ OPEN SEEL ---------------------//
            if((C1>100)&&(C2>100)&&(C3>100)&&(C2>C1)&&(C2>C3)) {
                ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"Ve:",99999,0,Red);
                flag=0;
                if(ticket<1) {
                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)==False) Print("OPEN SELL ORDER :  ",OrderOpenPrice());
                } else {
                    Print("-----ERROR-----  opening SEEL order : ",GetLastError());
                    return(0);
                }
           }
        //------------------ OPEN BUY ---------------------//
            if((C1<-100)&&(C2<-100)&&(C3<-100)&&(C2<C1)&&(C2<C3)) {
                ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"Ve:",99999,0,Blue);
                flag=0;
                if(ticket<1) {
                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)==False) Print("OPEN BUY ORDER ",OrderOpenPrice());
                } else {
                    Print("-----ERROR-----  opening BUY order : ",GetLastError());
                    return(0);
                }
            }
        }
        return(0);
    }

    {
        //------------------ CLOSE BUY ---------------------//
        OrderSelect(SELECT_BY_POS, MODE_TRADES);
            if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
                if(C1>100) {
                    OrderClose(OrderTicket(),OrderLots(),Bid,3,Black); // OUT
                    return(0);
                }
        //------------------ CLOSE SELL --------------------//
        OrderSelect(SELECT_BY_POS, MODE_TRADES);
            if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
                if(C1<-100) {
                    OrderClose(OrderTicket(),OrderLots(),Ask,3,White); // OUT
                    return(0);
                }
    }
    return(0);
  
}
//+------------------------- FINISH --------------------------------+

//+------------------- Trail Stop function --------------------------------+
//To Be Implemented
void trailStop (int myTrail) {
    int counts;//Order counts

    if (OrderSelect(OrdersTotal()-1,SELECT_BY_POS)==false) return(0);//Select Present Order

    if (OrdersTotal()>0) {
        for(counts=OrdersTotal();counts>=0;counts--) {
            if (OrderSelect(counts,SELECT_BY_POS)==false) continue;
            else {
                if (OrderProfit()>0 && OrderType()==0 && ((Bid-OrderStopLoss())> myTrail*Point))) {
                    OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point myTrail,OrderTakeProfit(),0);
                }

                if (OrderProfit()>0 && OrderType()==1 && ((OrderStopLoss()-Ask)> myTrail*Point))) {
                    OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point myTrail,OrderTakeProfit(),0);
                }
            }
        }
    }
 }

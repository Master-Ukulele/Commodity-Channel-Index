//+------------------------------------------------------------------+
//|                                                     CCI Only.mq4 |
//|                                                   Master-Ukulele |
//|                                                             None |
//+------------------------------------------------------------------+
#property copyright "Master-Ukulele"
#property link      "None"
#property version   "1.00"
#property strict

extern double     Lots =  0.01;
extern double     ORDER =    1;
extern int        chk =      0;
extern int        flag =     0;
extern int        se =       1;
extern int        bu =       1;

int start() {
    int ticket, total;
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
            chk = 1;
            if(flag == 0) {
                Print("Ready");
                flag = 1;
            }
        }

        if(chk == 1) {
        //------------------ OPEN SALE ---------------------//
            if((C1>100)&&(C2>100)&&(C3>100)&&(C2>C1)&&(C2>C3)&&(C1<160)&&(C2<160)&&(C3<160)&&(se=1)) {
                ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+200*Point,0,"Ve:",99999,0,Red);
                se = 0;
                bu = 1;
                flag = 0;
                if(ticket<1) {
                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)==False) Print("OPEN SELL ORDER :  ",OrderOpenPrice());
                } else {
                    Print("-----ERROR-----  opening SEEL order : ",GetLastError());
                    return(0);
                }
            }
        //------------------ OPEN BUY ---------------------//
            if((C1<-100)&&(C2<-100)&&(C3<-100)&&(C2<C1)&&(C2<C3)&&(C1>-160)&&(C2>-160)&&(C3>-160)&&(bu=1)) {
                ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-200*Point,0,"Ve:",99999,0,Blue);
                bu = 0;
                se = 1;
                flag = 0;
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
        OrderSelect(SELECT_BY_POS, MODE_TRADES)
            if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
                if((C2>100)&&(C2>C1)&&(C2>C3)) {
                    OrderClose(OrderTicket(),OrderLots(),Bid,3,Black); // OUT
                    bu=1;
                    return(0);
                }
    //------------------ CLOSE SELL --------------------//
        OrderSelect(SELECT_BY_POS, MODE_TRADES);
            if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
                if((C2<-100)&&(C2<C1)&&(C2<C3)) {
                    OrderClose(OrderTicket(),OrderLots(),Ask,3,White); // OUT
                    se=1;
                    return(0);
                }
    }
    return(0);
}
//+----------------------- FINISH --------------------------------+
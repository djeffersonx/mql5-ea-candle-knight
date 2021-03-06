//+------------------------------------------------------------------+
//|                                 SeQuexCashBot - CandleKnight.mq5 |
//|                                          Djefferson - SeQuexCash |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#include <SimpleCandleInfo.mqh>

#property indicator_chart_window 
#property indicator_buffers 1
#property indicator_plots   1 

#property indicator_label1  "MovingAverage" 
#property indicator_type1   DRAW_LINE 
#property indicator_color1  clrRed 
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  1 

#property copyright "Djefferson - SeQuexCash"
#property link      "https://www.mql5.com"
#property version   "1.00"

double MA_BUFFER[]; 
int MA_HANDLE; 
int MA_BARS_CALCULATED=0; 

MqlRates CANDLES[];

int OnInit(){
   SetIndexBuffer(0, MA_BUFFER,INDICATOR_DATA); 
   MA_HANDLE=iMA(_Symbol,_Period, 20,0,MODE_SMMA,PRICE_CLOSE); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   ArraySetAsSeries(CANDLES, true);
   ArraySetAsSeries(MA_BUFFER, true);
}

void OnTick(){

   CopyRates(_Symbol, _Period, 0, 5, CANDLES);   

   FillArrayFromBuffer(MA_BUFFER, 0, MA_HANDLE, 4);
   
   if(isNewBar()){
   
      CandleInfo candleInfo0 = getCandleInfo(CANDLES[0], 3);
      CandleInfo candleInfo1 = getCandleInfo(CANDLES[1], 3);
      CandleInfo candleInfo2 = getCandleInfo(CANDLES[2], 3);
      CandleInfo candleInfo3 = getCandleInfo(CANDLES[3], 3);

     if(candleInfo0.isBull() && candleInfo0.isStrong()
         && candleInfo1.isBull() && candleInfo1.isStrong() 
         && candleInfo2.isBull() && candleInfo2.isStrong()
         && candleInfo3.isBull() && candleInfo3.isStrong() && candleInfo3.isTrendUpper()){

         transactionAtMarket(ORDER_TYPE_BUY, CANDLES[0].low, getTakeProfit(candleInfo3));

      } else if(!candleInfo0.isBull() && candleInfo0.isStrong()
               && !candleInfo1.isBull() && candleInfo1.isStrong() 
               && !candleInfo2.isBull() && candleInfo2.isStrong()
               && !candleInfo3.isBull() && candleInfo3.isStrong() && candleInfo3.isTrendDown()){
      
         transactionAtMarket(ORDER_TYPE_SELL, CANDLES[0].high, getTakeProfit(candleInfo3));

      } 

   }

}

double getTakeProfit(CandleInfo &candle){
   double candle_size = (MathAbs(candle.open - candle.close))*4;
   if(!candle.isBull()){
      return candle.close - candle_size;
   }else if(candle.isBull()){
      return candle.close + candle_size;
   }
   return 0;
}

bool isNewBar(){
   static datetime last_time=0;
   datetime lastbar_time=SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   if(last_time==0) {
      last_time=lastbar_time;
      return(false);
   }
   if(last_time!=lastbar_time){
      last_time=lastbar_time;
      return(true);
   }
   return(false);
}

void transactionAtMarket(ENUM_ORDER_TYPE order_type, double stop_loss, double take_profit){

   MqlTradeRequest   requisicao;
   MqlTradeResult    resposta; 

   ZeroMemory(requisicao);
   ZeroMemory(resposta);

   requisicao.action    = TRADE_ACTION_DEAL;
   requisicao.magic     = 141414;

   requisicao.symbol    = _Symbol;
   requisicao.volume    = 1; 
   requisicao.price     = 0;

   requisicao.sl        = stop_loss;
   requisicao.tp        = take_profit;
   requisicao.deviation = 0;
   requisicao.type      = order_type;
   requisicao.type_filling = ORDER_FILLING_IOC;
   requisicao.type_time = ORDER_TIME_DAY;
   requisicao.expiration = 0;
   requisicao.comment   = "SeQuexCash = CandleKinight";
   
   ResetLastError();
   bool ok = OrderSend(requisicao,resposta);
   
   if(!ok) {
      Print("Erro ao enviar ordem. Erro # ",GetLastError());
   } else {
      Print("A ordem foi corretamente ENVIADA para a corretora!!!!");

      if( resposta.retcode==10008 || resposta.retcode==10009 ) {
         Print("Ordem executada.");
      } else {
         Print("Erro ao executar ordem. Erro # ",GetLastError()," / retorno = ",resposta.retcode);
      }
   }
}

int getValuesToCopy(int handle, int &barsCalculated, int ratesTotal, int prevCalculated){
   int valuesToCopy; 
   int calculated = BarsCalculated(handle); 

   if(calculated<=0)  { 
      return(0); 
   } 
   if(prevCalculated==0 || calculated!=barsCalculated || ratesTotal>prevCalculated+1) { 
      if(calculated>ratesTotal) {
         valuesToCopy=ratesTotal; 
      } else {
         valuesToCopy=calculated; 
      }
   }  else { 
      valuesToCopy=(ratesTotal-prevCalculated)+1; 
   } 
   
   barsCalculated=calculated; 
   return valuesToCopy;
}

bool FillArrayFromBuffer(double &values[], int shift, int handle, int amount ) { 
   ResetLastError(); 
   if(CopyBuffer(handle,0,-shift,amount,values)<0) { 
      return(false); 
   } 
   return(true); 
} 
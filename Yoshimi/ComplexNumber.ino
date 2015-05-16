
class ComplexNumber{
  float x;//real
  float y;//imaginary
  
  ComplexNumber(float real, float imaginary){
    x = real;
    y = imaginary;
  }
  //adds two complex numbers
  ComplexNumber plus(ComplexNumber comp){
    ComplexNumber newC = new ComplexNumber(this.x + comp.x, this.y + comp.y);
    return newC;
  }
  //subtracts two complex numbers
  ComplexNumber minus(ComplexNumber comp){
    ComplexNumber newC = new ComplexNumber(this.x - comp.x, this.y - comp.y);
    return newC;
  }
  //multiplies two complex numbers
  ComplexNumber times(ComplexNumber comp){
     float newA = this.x*comp.x - this.y*comp.y;
     float newB = this.x*comp.y + this.y*comp.x;
     ComplexNumber newC = new ComplexNumber(newA,newB);
     return newC;
  }
  //raises a complex number to a power
  ComplexNumber powered(float powNum){
    if(powNum == 0){
      ComplexNumber defCN = new ComplexNumber(1,0);
      return defCN;
    }else{
      ComplexNumber origCN = this;
      ComplexNumber newCN = this;
      for(int i = 1; i<powNum; i++){
        newCN = origCN.times(newCN);
      }
      return newCN;
    } 
  }
}

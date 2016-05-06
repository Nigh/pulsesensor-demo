


void setup(void)
{
  Serial.begin(115200);
}


void loop(void)
{
  Serial.print("x:");
  Serial.print(analogRead(A0));
  Serial.print(",\n");
  delay(20);
}




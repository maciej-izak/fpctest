{ This is an automatically created file, so don't edit it }
unit cp437;

  interface

  implementation

  uses
     {$ifdef VER2_2}ccharset{$else VER2_2}charset{$endif VER2_2};

  const
     map : array[0..255] of tunicodecharmapping = (
       (unicode : 0; flag : umf_noinfo; reserved : 0),
       (unicode : 1; flag : umf_noinfo; reserved : 0),
       (unicode : 2; flag : umf_noinfo; reserved : 0),
       (unicode : 3; flag : umf_noinfo; reserved : 0),
       (unicode : 4; flag : umf_noinfo; reserved : 0),
       (unicode : 5; flag : umf_noinfo; reserved : 0),
       (unicode : 6; flag : umf_noinfo; reserved : 0),
       (unicode : 7; flag : umf_noinfo; reserved : 0),
       (unicode : 8; flag : umf_noinfo; reserved : 0),
       (unicode : 9; flag : umf_noinfo; reserved : 0),
       (unicode : 10; flag : umf_noinfo; reserved : 0),
       (unicode : 11; flag : umf_noinfo; reserved : 0),
       (unicode : 12; flag : umf_noinfo; reserved : 0),
       (unicode : 13; flag : umf_noinfo; reserved : 0),
       (unicode : 14; flag : umf_noinfo; reserved : 0),
       (unicode : 15; flag : umf_noinfo; reserved : 0),
       (unicode : 16; flag : umf_noinfo; reserved : 0),
       (unicode : 17; flag : umf_noinfo; reserved : 0),
       (unicode : 18; flag : umf_noinfo; reserved : 0),
       (unicode : 19; flag : umf_noinfo; reserved : 0),
       (unicode : 20; flag : umf_noinfo; reserved : 0),
       (unicode : 21; flag : umf_noinfo; reserved : 0),
       (unicode : 22; flag : umf_noinfo; reserved : 0),
       (unicode : 23; flag : umf_noinfo; reserved : 0),
       (unicode : 24; flag : umf_noinfo; reserved : 0),
       (unicode : 25; flag : umf_noinfo; reserved : 0),
       (unicode : 26; flag : umf_noinfo; reserved : 0),
       (unicode : 27; flag : umf_noinfo; reserved : 0),
       (unicode : 28; flag : umf_noinfo; reserved : 0),
       (unicode : 29; flag : umf_noinfo; reserved : 0),
       (unicode : 30; flag : umf_noinfo; reserved : 0),
       (unicode : 31; flag : umf_noinfo; reserved : 0),
       (unicode : 32; flag : umf_noinfo; reserved : 0),
       (unicode : 33; flag : umf_noinfo; reserved : 0),
       (unicode : 34; flag : umf_noinfo; reserved : 0),
       (unicode : 35; flag : umf_noinfo; reserved : 0),
       (unicode : 36; flag : umf_noinfo; reserved : 0),
       (unicode : 37; flag : umf_noinfo; reserved : 0),
       (unicode : 38; flag : umf_noinfo; reserved : 0),
       (unicode : 39; flag : umf_noinfo; reserved : 0),
       (unicode : 40; flag : umf_noinfo; reserved : 0),
       (unicode : 41; flag : umf_noinfo; reserved : 0),
       (unicode : 42; flag : umf_noinfo; reserved : 0),
       (unicode : 43; flag : umf_noinfo; reserved : 0),
       (unicode : 44; flag : umf_noinfo; reserved : 0),
       (unicode : 45; flag : umf_noinfo; reserved : 0),
       (unicode : 46; flag : umf_noinfo; reserved : 0),
       (unicode : 47; flag : umf_noinfo; reserved : 0),
       (unicode : 48; flag : umf_noinfo; reserved : 0),
       (unicode : 49; flag : umf_noinfo; reserved : 0),
       (unicode : 50; flag : umf_noinfo; reserved : 0),
       (unicode : 51; flag : umf_noinfo; reserved : 0),
       (unicode : 52; flag : umf_noinfo; reserved : 0),
       (unicode : 53; flag : umf_noinfo; reserved : 0),
       (unicode : 54; flag : umf_noinfo; reserved : 0),
       (unicode : 55; flag : umf_noinfo; reserved : 0),
       (unicode : 56; flag : umf_noinfo; reserved : 0),
       (unicode : 57; flag : umf_noinfo; reserved : 0),
       (unicode : 58; flag : umf_noinfo; reserved : 0),
       (unicode : 59; flag : umf_noinfo; reserved : 0),
       (unicode : 60; flag : umf_noinfo; reserved : 0),
       (unicode : 61; flag : umf_noinfo; reserved : 0),
       (unicode : 62; flag : umf_noinfo; reserved : 0),
       (unicode : 63; flag : umf_noinfo; reserved : 0),
       (unicode : 64; flag : umf_noinfo; reserved : 0),
       (unicode : 65; flag : umf_noinfo; reserved : 0),
       (unicode : 66; flag : umf_noinfo; reserved : 0),
       (unicode : 67; flag : umf_noinfo; reserved : 0),
       (unicode : 68; flag : umf_noinfo; reserved : 0),
       (unicode : 69; flag : umf_noinfo; reserved : 0),
       (unicode : 70; flag : umf_noinfo; reserved : 0),
       (unicode : 71; flag : umf_noinfo; reserved : 0),
       (unicode : 72; flag : umf_noinfo; reserved : 0),
       (unicode : 73; flag : umf_noinfo; reserved : 0),
       (unicode : 74; flag : umf_noinfo; reserved : 0),
       (unicode : 75; flag : umf_noinfo; reserved : 0),
       (unicode : 76; flag : umf_noinfo; reserved : 0),
       (unicode : 77; flag : umf_noinfo; reserved : 0),
       (unicode : 78; flag : umf_noinfo; reserved : 0),
       (unicode : 79; flag : umf_noinfo; reserved : 0),
       (unicode : 80; flag : umf_noinfo; reserved : 0),
       (unicode : 81; flag : umf_noinfo; reserved : 0),
       (unicode : 82; flag : umf_noinfo; reserved : 0),
       (unicode : 83; flag : umf_noinfo; reserved : 0),
       (unicode : 84; flag : umf_noinfo; reserved : 0),
       (unicode : 85; flag : umf_noinfo; reserved : 0),
       (unicode : 86; flag : umf_noinfo; reserved : 0),
       (unicode : 87; flag : umf_noinfo; reserved : 0),
       (unicode : 88; flag : umf_noinfo; reserved : 0),
       (unicode : 89; flag : umf_noinfo; reserved : 0),
       (unicode : 90; flag : umf_noinfo; reserved : 0),
       (unicode : 91; flag : umf_noinfo; reserved : 0),
       (unicode : 92; flag : umf_noinfo; reserved : 0),
       (unicode : 93; flag : umf_noinfo; reserved : 0),
       (unicode : 94; flag : umf_noinfo; reserved : 0),
       (unicode : 95; flag : umf_noinfo; reserved : 0),
       (unicode : 96; flag : umf_noinfo; reserved : 0),
       (unicode : 97; flag : umf_noinfo; reserved : 0),
       (unicode : 98; flag : umf_noinfo; reserved : 0),
       (unicode : 99; flag : umf_noinfo; reserved : 0),
       (unicode : 100; flag : umf_noinfo; reserved : 0),
       (unicode : 101; flag : umf_noinfo; reserved : 0),
       (unicode : 102; flag : umf_noinfo; reserved : 0),
       (unicode : 103; flag : umf_noinfo; reserved : 0),
       (unicode : 104; flag : umf_noinfo; reserved : 0),
       (unicode : 105; flag : umf_noinfo; reserved : 0),
       (unicode : 106; flag : umf_noinfo; reserved : 0),
       (unicode : 107; flag : umf_noinfo; reserved : 0),
       (unicode : 108; flag : umf_noinfo; reserved : 0),
       (unicode : 109; flag : umf_noinfo; reserved : 0),
       (unicode : 110; flag : umf_noinfo; reserved : 0),
       (unicode : 111; flag : umf_noinfo; reserved : 0),
       (unicode : 112; flag : umf_noinfo; reserved : 0),
       (unicode : 113; flag : umf_noinfo; reserved : 0),
       (unicode : 114; flag : umf_noinfo; reserved : 0),
       (unicode : 115; flag : umf_noinfo; reserved : 0),
       (unicode : 116; flag : umf_noinfo; reserved : 0),
       (unicode : 117; flag : umf_noinfo; reserved : 0),
       (unicode : 118; flag : umf_noinfo; reserved : 0),
       (unicode : 119; flag : umf_noinfo; reserved : 0),
       (unicode : 120; flag : umf_noinfo; reserved : 0),
       (unicode : 121; flag : umf_noinfo; reserved : 0),
       (unicode : 122; flag : umf_noinfo; reserved : 0),
       (unicode : 123; flag : umf_noinfo; reserved : 0),
       (unicode : 124; flag : umf_noinfo; reserved : 0),
       (unicode : 125; flag : umf_noinfo; reserved : 0),
       (unicode : 126; flag : umf_noinfo; reserved : 0),
       (unicode : 127; flag : umf_noinfo; reserved : 0),
       (unicode : 199; flag : umf_noinfo; reserved : 0),
       (unicode : 252; flag : umf_noinfo; reserved : 0),
       (unicode : 233; flag : umf_noinfo; reserved : 0),
       (unicode : 226; flag : umf_noinfo; reserved : 0),
       (unicode : 228; flag : umf_noinfo; reserved : 0),
       (unicode : 224; flag : umf_noinfo; reserved : 0),
       (unicode : 229; flag : umf_noinfo; reserved : 0),
       (unicode : 231; flag : umf_noinfo; reserved : 0),
       (unicode : 234; flag : umf_noinfo; reserved : 0),
       (unicode : 235; flag : umf_noinfo; reserved : 0),
       (unicode : 232; flag : umf_noinfo; reserved : 0),
       (unicode : 239; flag : umf_noinfo; reserved : 0),
       (unicode : 238; flag : umf_noinfo; reserved : 0),
       (unicode : 236; flag : umf_noinfo; reserved : 0),
       (unicode : 196; flag : umf_noinfo; reserved : 0),
       (unicode : 197; flag : umf_noinfo; reserved : 0),
       (unicode : 201; flag : umf_noinfo; reserved : 0),
       (unicode : 230; flag : umf_noinfo; reserved : 0),
       (unicode : 198; flag : umf_noinfo; reserved : 0),
       (unicode : 244; flag : umf_noinfo; reserved : 0),
       (unicode : 246; flag : umf_noinfo; reserved : 0),
       (unicode : 242; flag : umf_noinfo; reserved : 0),
       (unicode : 251; flag : umf_noinfo; reserved : 0),
       (unicode : 249; flag : umf_noinfo; reserved : 0),
       (unicode : 255; flag : umf_noinfo; reserved : 0),
       (unicode : 214; flag : umf_noinfo; reserved : 0),
       (unicode : 220; flag : umf_noinfo; reserved : 0),
       (unicode : 162; flag : umf_noinfo; reserved : 0),
       (unicode : 163; flag : umf_noinfo; reserved : 0),
       (unicode : 165; flag : umf_noinfo; reserved : 0),
       (unicode : 8359; flag : umf_noinfo; reserved : 0),
       (unicode : 402; flag : umf_noinfo; reserved : 0),
       (unicode : 225; flag : umf_noinfo; reserved : 0),
       (unicode : 237; flag : umf_noinfo; reserved : 0),
       (unicode : 243; flag : umf_noinfo; reserved : 0),
       (unicode : 250; flag : umf_noinfo; reserved : 0),
       (unicode : 241; flag : umf_noinfo; reserved : 0),
       (unicode : 209; flag : umf_noinfo; reserved : 0),
       (unicode : 170; flag : umf_noinfo; reserved : 0),
       (unicode : 186; flag : umf_noinfo; reserved : 0),
       (unicode : 191; flag : umf_noinfo; reserved : 0),
       (unicode : 8976; flag : umf_noinfo; reserved : 0),
       (unicode : 172; flag : umf_noinfo; reserved : 0),
       (unicode : 189; flag : umf_noinfo; reserved : 0),
       (unicode : 188; flag : umf_noinfo; reserved : 0),
       (unicode : 161; flag : umf_noinfo; reserved : 0),
       (unicode : 171; flag : umf_noinfo; reserved : 0),
       (unicode : 187; flag : umf_noinfo; reserved : 0),
       (unicode : 9617; flag : umf_noinfo; reserved : 0),
       (unicode : 9618; flag : umf_noinfo; reserved : 0),
       (unicode : 9619; flag : umf_noinfo; reserved : 0),
       (unicode : 9474; flag : umf_noinfo; reserved : 0),
       (unicode : 9508; flag : umf_noinfo; reserved : 0),
       (unicode : 9569; flag : umf_noinfo; reserved : 0),
       (unicode : 9570; flag : umf_noinfo; reserved : 0),
       (unicode : 9558; flag : umf_noinfo; reserved : 0),
       (unicode : 9557; flag : umf_noinfo; reserved : 0),
       (unicode : 9571; flag : umf_noinfo; reserved : 0),
       (unicode : 9553; flag : umf_noinfo; reserved : 0),
       (unicode : 9559; flag : umf_noinfo; reserved : 0),
       (unicode : 9565; flag : umf_noinfo; reserved : 0),
       (unicode : 9564; flag : umf_noinfo; reserved : 0),
       (unicode : 9563; flag : umf_noinfo; reserved : 0),
       (unicode : 9488; flag : umf_noinfo; reserved : 0),
       (unicode : 9492; flag : umf_noinfo; reserved : 0),
       (unicode : 9524; flag : umf_noinfo; reserved : 0),
       (unicode : 9516; flag : umf_noinfo; reserved : 0),
       (unicode : 9500; flag : umf_noinfo; reserved : 0),
       (unicode : 9472; flag : umf_noinfo; reserved : 0),
       (unicode : 9532; flag : umf_noinfo; reserved : 0),
       (unicode : 9566; flag : umf_noinfo; reserved : 0),
       (unicode : 9567; flag : umf_noinfo; reserved : 0),
       (unicode : 9562; flag : umf_noinfo; reserved : 0),
       (unicode : 9556; flag : umf_noinfo; reserved : 0),
       (unicode : 9577; flag : umf_noinfo; reserved : 0),
       (unicode : 9574; flag : umf_noinfo; reserved : 0),
       (unicode : 9568; flag : umf_noinfo; reserved : 0),
       (unicode : 9552; flag : umf_noinfo; reserved : 0),
       (unicode : 9580; flag : umf_noinfo; reserved : 0),
       (unicode : 9575; flag : umf_noinfo; reserved : 0),
       (unicode : 9576; flag : umf_noinfo; reserved : 0),
       (unicode : 9572; flag : umf_noinfo; reserved : 0),
       (unicode : 9573; flag : umf_noinfo; reserved : 0),
       (unicode : 9561; flag : umf_noinfo; reserved : 0),
       (unicode : 9560; flag : umf_noinfo; reserved : 0),
       (unicode : 9554; flag : umf_noinfo; reserved : 0),
       (unicode : 9555; flag : umf_noinfo; reserved : 0),
       (unicode : 9579; flag : umf_noinfo; reserved : 0),
       (unicode : 9578; flag : umf_noinfo; reserved : 0),
       (unicode : 9496; flag : umf_noinfo; reserved : 0),
       (unicode : 9484; flag : umf_noinfo; reserved : 0),
       (unicode : 9608; flag : umf_noinfo; reserved : 0),
       (unicode : 9604; flag : umf_noinfo; reserved : 0),
       (unicode : 9612; flag : umf_noinfo; reserved : 0),
       (unicode : 9616; flag : umf_noinfo; reserved : 0),
       (unicode : 9600; flag : umf_noinfo; reserved : 0),
       (unicode : 945; flag : umf_noinfo; reserved : 0),
       (unicode : 223; flag : umf_noinfo; reserved : 0),
       (unicode : 915; flag : umf_noinfo; reserved : 0),
       (unicode : 960; flag : umf_noinfo; reserved : 0),
       (unicode : 931; flag : umf_noinfo; reserved : 0),
       (unicode : 963; flag : umf_noinfo; reserved : 0),
       (unicode : 181; flag : umf_noinfo; reserved : 0),
       (unicode : 964; flag : umf_noinfo; reserved : 0),
       (unicode : 934; flag : umf_noinfo; reserved : 0),
       (unicode : 920; flag : umf_noinfo; reserved : 0),
       (unicode : 937; flag : umf_noinfo; reserved : 0),
       (unicode : 948; flag : umf_noinfo; reserved : 0),
       (unicode : 8734; flag : umf_noinfo; reserved : 0),
       (unicode : 966; flag : umf_noinfo; reserved : 0),
       (unicode : 949; flag : umf_noinfo; reserved : 0),
       (unicode : 8745; flag : umf_noinfo; reserved : 0),
       (unicode : 8801; flag : umf_noinfo; reserved : 0),
       (unicode : 177; flag : umf_noinfo; reserved : 0),
       (unicode : 8805; flag : umf_noinfo; reserved : 0),
       (unicode : 8804; flag : umf_noinfo; reserved : 0),
       (unicode : 8992; flag : umf_noinfo; reserved : 0),
       (unicode : 8993; flag : umf_noinfo; reserved : 0),
       (unicode : 247; flag : umf_noinfo; reserved : 0),
       (unicode : 8776; flag : umf_noinfo; reserved : 0),
       (unicode : 176; flag : umf_noinfo; reserved : 0),
       (unicode : 8729; flag : umf_noinfo; reserved : 0),
       (unicode : 183; flag : umf_noinfo; reserved : 0),
       (unicode : 8730; flag : umf_noinfo; reserved : 0),
       (unicode : 8319; flag : umf_noinfo; reserved : 0),
       (unicode : 178; flag : umf_noinfo; reserved : 0),
       (unicode : 9632; flag : umf_noinfo; reserved : 0),
       (unicode : 160; flag : umf_noinfo; reserved : 0)
     );

     unicodemap : tunicodemap = (
       cpname : 'cp437';
       cp : 437;     
       map : @map[0];
       lastchar : 255;
       next : nil;
       internalmap : true
     );

  begin
     registermapping(@unicodemap)
  end.

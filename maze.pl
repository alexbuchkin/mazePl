% constants
cMaxUpperWallLength(2.0).
cFirstLayerRoomNumber(4).
cDelta(1.0).


getInnerCircleLengthByLayer(LayerNumber, Length)
    :- cDelta(D)
     , R is D * LayerNumber
     , Length is 2 * pi * R
     .

getOuterCircleLengthByLayer(LayerNumber, Length)
    :- NextLayerNumber is LayerNumber + 1
     , getInnerCircleLengthByLayer(NextLayerNumber, Length)
     .

getRoomCountByLayer(1, RoomCount)
    :- cFirstLayerRoomNumber(RoomCount)
     , !
     .
getRoomCountByLayer(LayerNumber, RoomCount)
    :- PrevLayerNumber is LayerNumber - 1
     , getRoomCountByLayer(PrevLayerNumber, PrevLayerRoomCount)
     , getOuterCircleLengthByLayer(LayerNumber, Length)
     , UpperWallLength is Length / PrevLayerRoomCount
     , cMaxUpperWallLength(MaxUpperWallLength)
     , UpperWallLength =< MaxUpperWallLength
     , !
     , RoomCount is PrevLayerRoomCount
     .
getRoomCountByLayer(LayerNumber, RoomCount)
    :- PrevLayerNumber is LayerNumber - 1
     , getRoomCountByLayer(PrevLayerNumber, PrevLayerRoomCount)
     , RoomCount is 2 * PrevLayerRoomCount
     .
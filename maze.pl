:- use_module(library(pce)).


% --------------------------------------------------------constants---------------------------------------------
c_max_upper_wall_length(100.0).
c_first_ring_room_count(4).
c_delta(35.0).


% --------------------------------------------------------maze-generating---------------------------------------

get_inner_circle_length(RingNumber, Length)
    :- c_delta(D)
     , R is D * RingNumber
     , Length is 2 * pi * R
     .

get_outer_circle_length(RingNumber, Length)
    :- NextRingNumber is RingNumber + 1
     , get_inner_circle_length(NextRingNumber, Length)
     .

get_room_count(1, RoomCount)
    :- !
     , c_first_ring_room_count(RoomCount)
     .
get_room_count(RingNumber, RoomCount)
    :- PrevRingNumber is RingNumber - 1
     , get_room_count(PrevRingNumber, PrevRingRoomCount)
     , get_outer_circle_length(RingNumber, Length)
     , UpperWallLength is Length / PrevRingRoomCount
     , c_max_upper_wall_length(MaxUpperWallLength)
     , UpperWallLength =< MaxUpperWallLength
     , !
     , RoomCount is PrevRingRoomCount
     .
get_room_count(RingNumber, RoomCount)
    :- PrevRingNumber is RingNumber - 1
     , get_room_count(PrevRingNumber, PrevRingRoomCount)
     , RoomCount is 2 * PrevRingRoomCount
     .

count_rooms_in_total(1, TotalRoomNumber)
    :- !
     , c_first_ring_room_count(TotalRoomNumber)
     .

count_rooms_in_total(RingNumber, TotalRoomNumber)
    :- RDec is RingNumber - 1
     , count_rooms_in_total(RDec, TotalPrev)
     , get_room_count(RingNumber, Count)
     , TotalRoomNumber is TotalPrev + Count
     .

choose_random_room_number(RingNumber, RandomRoomNumber)
    :- get_room_count(RingNumber, RoomCount)
     , RCDec is RoomCount - 1
     , random_between(0, RCDec, RandomRoomNumber)
     .

generate_maze(RingNumber, EntryRoomNumber, ExitRoomNumber, Connections)
    :- choose_random_room_number(1, EntryRoomNumber)
     , choose_random_room_number(RingNumber, ExitRoomNumber)
     , connect(RingNumber, [room(1, EntryRoomNumber)], Connections)
     .

connect(RingNumber, VisitedRooms, Connections)
    :- connect1(RingNumber, VisitedRooms, [], Connections)
     .

connect1(RingNumber, VisitedRooms, Connections, Connections)
    :- count_rooms_in_total(RingNumber, TotalRoomNumber)
     , length(VisitedRooms, TotalRoomNumber)
     , !
     .

connect1(RingNumber, VisitedRooms, CurrentConnections, Connections)
    :- get_all_connections_from_visited_to_unvisited(RingNumber, VisitedRooms, SuggestedConnections)
     , increase_in_ring_chance(SuggestedConnections, NewSuggestedConnections)  % might be useful
     , random_member(connection(Visited, Unvisited), NewSuggestedConnections)
     , connect1(RingNumber, [Unvisited | VisitedRooms], [connection(Visited, Unvisited) | CurrentConnections], Connections)
     .

% -------- trying to make maze more difficult to solve
take_in_ring_connections([], []) :- !.
take_in_ring_connections([connection(room(R, S1), room(R, S2)) | T1], [connection(room(R, S1), room(R, S2)) | T2])
    :- !
     , take_in_ring_connections(T1, T2)
     .
take_in_ring_connections([_ | T1], L2)
    :- take_in_ring_connections(T1, L2)
     .

increase_in_ring_chance(Connections, NewConn)
    :- take_in_ring_connections(Connections, InRing)
     , append(InRing, InRing, L1)
     , append(L1, L1, L2)
     , append(L2, L2, L3)
     , append(L3, Connections, NewConn)
     .
% ---------

get_all_connections_from_visited_to_unvisited(RingNumber, VisitedRooms, Connections)
    :- get_vtouv(RingNumber, VisitedRooms, VisitedRooms, [], Connections)
     .

get_vtouv(_, [], _, Connections, Connections)
    :- !
     .

get_vtouv(RingNumber, [Room | T], VisitedRooms, CurrentConnections, Connections)
    :- get_neighbors(RingNumber, Room, Neighbors)
     , drop_visited(Neighbors, VisitedRooms, UnvisitedNeighbors)
     , findall(connection(Room, NeighborRoom), member(NeighborRoom, UnvisitedNeighbors), ThisRoomConnections)
     , append(CurrentConnections, ThisRoomConnections, NewConn)
     , get_vtouv(RingNumber, T, VisitedRooms, NewConn, Connections)
     .

get_neighbors(RingNumber, Room, Neighbors)
    :- get_left_neighbor(Room, L)
     , get_right_neighbor(Room, R)
     , get_down_neighbor(Room, D)  % D is list with length <= 1
     , get_upper_neighbors(RingNumber, Room, U)  % U is list with length <= 2
     , append([L, R | D], U, Neighbors)
     .

get_left_neighbor(room(CurrentRing, CurrentSector), room(CurrentRing, LeftSector))
    :- get_room_count(CurrentRing, RoomCount)
     , LeftSector is (CurrentSector + 1) mod RoomCount
     .

get_right_neighbor(room(CurrentRing, CurrentSector), room(CurrentRing, RightSector))
    :- get_room_count(CurrentRing, RoomCount)
     , RightSector is (CurrentSector + RoomCount - 1) mod RoomCount
     .

get_down_neighbor(room(1, _), [])
    :- !
     .

get_down_neighbor(room(CurrentRing, CurrentSector), [room(Ring, CurrentSector)])
    :- Ring is CurrentRing - 1
     , get_room_count(CurrentRing, RoomCount)
     , get_room_count(Ring, RoomCount)
     , !
     .

get_down_neighbor(room(CurrentRing, CurrentSector), [room(Ring, Sector)])
    :- Ring is CurrentRing - 1
     , Sector is CurrentSector div 2
     .

get_upper_neighbors(RingNumber, room(RingNumber, _), [])
    :- !
     .

get_upper_neighbors(_, room(CurrentRing, CurrentSector), [room(Ring, CurrentSector)])
    :- Ring is CurrentRing + 1
     , get_room_count(Ring, RoomCount)
     , get_room_count(CurrentRing, RoomCount)
     , !
     .

get_upper_neighbors(_, room(CurrentRing, CurrentSector), [room(Ring, S1), room(Ring, S2)])
    :- Ring is CurrentRing + 1
     , S1 is CurrentSector * 2
     , S2 is S1 + 1
     .

drop_visited(Neighbors, VisitedRooms, UnvisitedNeighbors)
    :- drop_vis1(Neighbors, VisitedRooms, [], UnvisitedNeighbors)
     .

drop_vis1([], _, UnvisitedNeighbors, UnvisitedNeighbors).

drop_vis1([Room | T], VisitedRooms, Accum, UnvisitedNeighbors)
    :- member(Room, VisitedRooms)
     , !
     , drop_vis1(T, VisitedRooms, Accum, UnvisitedNeighbors)
     .

drop_vis1([Room | T], VisitedRooms, Accum, UnvisitedNeighbors)
    :- drop_vis1(T, VisitedRooms, [Room | Accum], UnvisitedNeighbors)
     .


% --------------------------------------------------------maze-drawing---------------------------------------

draw_maze(RingNumber, Connections, EntryRoomNumber, ExitRoomNumber, Path)
    :- new(DW, dialog('M'))
     , new(Picture, picture('Maze'))
     , send(Picture, width(800))
     , send(Picture, height(600))
     , draw_inner_circle(EntryRoomNumber, InnerCircle)
     , draw_outer_circle(RingNumber, ExitRoomNumber, OuterCircle)
     , draw_walls(RingNumber, Connections, Walls)
     , append([InnerCircle, OuterCircle | Walls], Path, All)
     %, send_list(Picture, display, All)
     , send_list(Picture, display, [InnerCircle, OuterCircle | Walls])
     , send(DW, append, Picture)
     , send(DW, open)
     .

draw_inner_circle(EntryRoomNumber, InnerCircle)
    :- c_delta(Radius)
     , get_inner_circle_length(1, CircleLength)
     , get_room_count(1, RoomCount)
     , Angle is 360 / RoomCount * (EntryRoomNumber + 1)
     , Size is 360 - 360 / RoomCount
     , InnerCircle = arc(Radius, Angle, Size)
     .

draw_outer_circle(RingNumber, ExitRoomNumber, OuterCircle)
    :- c_delta(D)
     , Radius is D * (RingNumber + 1)
     , get_outer_circle_length(RingNumber, CircleLength)
     , get_room_count(RingNumber, RoomCount)
     , Angle is 360 / RoomCount * (ExitRoomNumber + 1)
     , Size is 360 - 360 / RoomCount
     , OuterCircle = arc(Radius, Angle, Size)
     .

draw_walls(RingNumber, Connections, Walls)
    :- draw_w(1, RingNumber, Connections, [], Walls)
     .

draw_w(CurrentRingNumber, RingNumber, _, Walls, Walls)
    :- CurrentRingNumber > RingNumber
     , !
     .

draw_w(CurrentRingNumber, RingNumber, Connections, CurrentWalls, Walls)
    :- get_walls_for_ring(CurrentRingNumber, RingNumber, Connections, ThisRingWalls)
     , append(ThisRingWalls, CurrentWalls, CW)
     , NextRingNumber is CurrentRingNumber + 1
     , draw_w(NextRingNumber, RingNumber, Connections, CW, Walls)
     .

get_walls_for_ring(CurrentRingNumber, RingNumber, Connections, Walls)
    :- get_lu_connections_for_ring(CurrentRingNumber, RingNumber, AllConnections)
     , filter_walls(AllConnections, Connections, WallsConn)
     , map_draw_walls_by_connections(WallsConn, Walls)
     .

get_lu_connections_for_ring(CurrentRingNumber, RingNumber, Connections)
    :- get_room_count(CurrentRingNumber, RoomCount)
     , get_lu(0, RoomCount, CurrentRingNumber, RingNumber, [], Connections)
     .

get_lu(RoomCount, RoomCount, _, _, Connections, Connections)
    :- !
     .

get_lu(RoomIndex, RoomCount, CurrentRingNumber, RingNumber, CurrentConnections, Connections)
    :- ThisRoom = room(CurrentRingNumber, RoomIndex)
     , get_left_neighbor(ThisRoom, LeftNeighbor)
     , get_upper_neighbors(RingNumber, ThisRoom, UpperNeighbors)
     , findall(connection(ThisRoom, NeighborRoom), member(NeighborRoom, [LeftNeighbor | UpperNeighbors]), ThisRoomConnections)
     , append(ThisRoomConnections, CurrentConnections, NewConn)
     , NextRoomIndex is RoomIndex + 1
     , get_lu(NextRoomIndex, RoomCount, CurrentRingNumber, RingNumber, NewConn, Connections)
     .

filter_walls([], _, [])
    :- !
     .

filter_walls([connection(A, B) | AllTail], Excluded, [connection(A, B) | WallsTail])
    :- not(member(connection(A, B), Excluded))
     , not(member(connection(B, A), Excluded))
     , !
     , filter_walls(AllTail, Excluded, WallsTail)
     .

filter_walls([_ | AllTail], Excluded, Walls)
    :- filter_walls(AllTail, Excluded, Walls)
     .

map_draw_walls_by_connections([], [])
    :- !
     .

map_draw_walls_by_connections([connection(room(RingNumber, RoomIndex), room(RingNumber, LeftRoomIndex)) | ConnTail], [Pic | WallsTail])
    :- !
     , get_room_count(RingNumber, RoomCount)
     , c_delta(D)
     , InnerRadius is D * RingNumber
     , OuterRadius is D * (RingNumber + 1)
     , StartX is InnerRadius * cos(2 * pi / RoomCount * LeftRoomIndex)
     , StartY is -InnerRadius * sin(2 * pi / RoomCount * LeftRoomIndex)
     , EndX is OuterRadius * cos(2 * pi / RoomCount * LeftRoomIndex)
     , EndY is -OuterRadius * sin(2 * pi / RoomCount * LeftRoomIndex)
     , Pic = line(StartX, StartY, EndX, EndY)
     , map_draw_walls_by_connections(ConnTail, WallsTail)
     .

map_draw_walls_by_connections([connection(room(RingNumber, RoomIndex), room(_, UpperRoomIndex)) | ConnTail], [Pic | WallsTail])
    :- c_delta(D)
     , Radius is D * (RingNumber + 1)
     , get_upper_wall_params(RingNumber, RoomIndex, UpperRoomIndex, Angle, Size)
     , Pic = arc(Radius, Angle, Size)
     , map_draw_walls_by_connections(ConnTail, WallsTail)
     .

get_upper_wall_params(RingNumber, RoomIndex, RoomIndex, Angle, Size)
    :- NextRingNumber is RingNumber + 1
     , get_room_count(RingNumber, RoomCount)
     , get_room_count(NextRingNumber, RoomCount)
     , !
     , Angle is 360 / RoomCount * RoomIndex
     , get_outer_circle_length(RingNumber, OuterLength)
     , Size is 360 / RoomCount
     .

get_upper_wall_params(RingNumber, RoomIndex, UpperRoomIndex, Angle, Size)
    :- NextRingNumber is RingNumber + 1
     , get_room_count(NextRingNumber, NextRingRoomCount)
     , get_outer_circle_length(RingNumber, OuterLength)
     , Angle is 360 / NextRingRoomCount * UpperRoomIndex
     , Size is 360 / NextRingRoomCount
     .



% --------------------------------------------------------path-finding---------------------------------------

find_path(StartRoom, Goal, RingNumber, Connections, Path)
    :- dfs(StartRoom, Goal, RingNumber, Connections, [StartRoom], Path)
     .

dfs(Goal, Goal, _, _, [Goal | Path], [Goal | Path])
    :- !
     .

dfs(Room, Goal, RingNumber, Connections, [Room | Path], Result)
    :- get_connected_neighbors(Room, Connections, Neighbors)
     , dfs_from_neighbors(Room, Goal, RingNumber, Connections, Neighbors, [Room | Path], Result)
     .

get_connected_neighbors(Room, Connections, Neighbors)
    :- findall(Neigh, member(connection(Room, Neigh), Connections), L1)
     , findall(Neigh, member(connection(Neigh, Room), Connections), L2)
     , append(L1, L2, Neighbors)
     .

dfs_from_neighbors(_, _, _, _, [], _, nil)
    :- !
     .

dfs_from_neighbors(Room, Goal, RingNumber, Connections, [Neigh | NTail], Path, Result)
    :- not(member(Neigh, Path))
     , dfs(Neigh, Goal, RingNumber, Connections, [Neigh | Path], NeighResult)
     , dif(NeighResult, nil)
     , !
     , Result = NeighResult
     .

dfs_from_neighbors(Room, Goal, RingNumber, Connections, [_ | NTail], Path, Result)
    :- dfs_from_neighbors(Room, Goal, RingNumber, Connections, NTail, Path, Result)
     .

% --------------------------------------------------------path-drawing---------------------------------------

draw_path(Path, Lines)
    :- last(Path, EntryRoom)
     , nth0(0, Path, ExitRoom)
     , draw_entry(EntryRoom, EntryLine)
     , draw_exit(ExitRoom, ExitLine)
     , draw_path1(Path, MidLines)
     , Lines = [EntryLine, ExitLine | MidLines]
     .

draw_entry(room(RingIndex, RoomIndex), EntryLine)
    :- get_room_count(RingIndex, RoomCount)
     , c_delta(D)
     , InnerRadius is D * RingIndex
     , EndX is (InnerRadius + D / 2) * cos(pi / RoomCount * (2 * RoomIndex + 1))
     , EndY is -(InnerRadius + D / 2) * sin(pi / RoomCount * (2 * RoomIndex + 1))
     , EntryLine = line(0.0, 0.0, EndX, EndY)
     .

draw_exit(room(RingIndex, RoomIndex), ExitLine)
    :- get_room_count(RingIndex, RoomCount)
     , c_delta(D)
     , Radius is D * RingIndex + D / 2
     , StartX is Radius * cos(pi / RoomCount * (2 * RoomIndex + 1))
     , StartY is -Radius * sin(pi / RoomCount * (2 * RoomIndex + 1))
     , EndX is (Radius + D) * cos(pi / RoomCount * (2 * RoomIndex + 1))
     , EndY is -(Radius + D) * sin(pi / RoomCount * (2 * RoomIndex + 1))
     , ExitLine = line(StartX, StartY, EndX, EndY)
     .

draw_path1([_], [])
    :- !
     .

draw_path1([room(RingIndex, S1), room(RingIndex, S2) | T], [Arc | LT])
    :- !
     , c_delta(D)
     , Radius is D * RingIndex + D / 2
     , get_room_count(RingIndex, RoomCount)
     , right_index(S1, S2, S)
     , Start is 360 / RoomCount / 2 * (2 * S + 1)
     , Size is 360 / RoomCount
     , Arc = arc(Radius, Start, Size)
     , draw_path1([room(RingIndex, S2) | T], LT)
     .

draw_path1([room(R1, S1), room(R2, S2) | T], [Line | LT])
    :- get_center(R1, S1, X1, Y1)
     , get_center(R2, S2, X2, Y2)
     , Line = line(X1, Y1, X2, Y2)
     , draw_path1([room(R2, S2) | T], LT)
     .

right_index(0, 1, 0) :- !.
right_index(1, 0, 0) :- !.
right_index(0, I, I) :- !.
right_index(I, 0, I) :- !.
right_index(A, B, Result)
    :- Result is min(A, B)
     .

get_center(RingIndex, RoomIndex, X, Y)
    :- c_delta(D)
     , Radius is D * RingIndex + D / 2
     , get_room_count(RingIndex, RoomCount)
     , X is Radius * cos(pi / RoomCount * (2 * RoomIndex + 1))
     , Y is -Radius * sin(pi / RoomCount * (2 * RoomIndex + 1))
     .





my_maze(RingNumber)
    :- generate_maze(RingNumber, EntryRoomNumber, ExitRoomNumber, Connections)
     , find_path(room(1, EntryRoomNumber), room(RingNumber, ExitRoomNumber), RingNumber, Connections, Path)
     , draw_path(Path, PathLines)
     , draw_maze(RingNumber, Connections, EntryRoomNumber, ExitRoomNumber, PathLines)
     .
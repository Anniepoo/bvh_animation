:- module(bvh_animation, [
              bvh_read_animation/2
 /*             bvh_write_animation/3,
              bvh_append_frame/2,
              bvh_read_frame/2,
              bvh_await_frame/2    */
          ]).
/** <module> Utilities for reading and writing bvh files.
 *
 * The BVH file format consists of a **skeleton**, a **motion** section with the number
 * of frames and frame time, and a sequence of frames
 *
 * each frame is a space separated list of floats for the variables in
 * the skeleton, as encountered in prefix traversal order.
 *
 * This pack provides facilities for reading and writing whole
 * animations, and for reading and writing frames.
 *
 */
:- use_module(library(dcg/basics)).

bvh_read_animation(File, bvh{
                             skeletons: Skeletons,
                             frame_time: FT,
                             frames: Frames
                         }) :-
    phrase_from_file(bvh_file(Skeletons, FT, Frames), File).


		 /*******************************
		 *            bvh format        *
		 *******************************/

% TODO add error messages
%
bvh_file(Skeletons, FT, Frames) -->
    marker_line(`HIERARCHY`),
    skeletons(Skeletons),
    motion_section_header(FT),
    frames(Frames).

w --> whites,!.
w --> [].


skeletons([Skeleton | Rest]) -->
    skeleton(Skeleton),
    skeletons(Rest).
skeletons([]) --> [].

skeleton(root(Name, Offset, Channels, Joints)) -->
    id_line(`ROOT`, Name),
    open_curly,
    offset_line(Offset),
    channels(Channels),
    joints_or_end_site(Joints),
    close_curly.

marker_line(Name) -->
    w,
    Name,
    w,
    `\n`.

motion_section_header(FT) -->
    w,
    `Frames:`,
    w,
    float(_),
    w,
    `\n`,
    w,
    `Frame Time:`,
    w,
    float(FT),
    w,
    `\n`.

close_curly --> w, `}`, w, `\n`.

open_curly --> w, `{`, w, `\n`.

id_line(Type, Name) --> w, Type, w, ident(Name), w, `\n`.

ident_code(X) -->
    [X],
    { (code_type(X, alnum) ; member(X, [ 46 , 0'_ , 0'- ]))},  % 46 is period
    !.

ident(Name) -->
    ident_code(X),
    ident_(NameC),
    !,
    { atom_codes(Name, [X | NameC]) }.

ident_([X | Rest]) -->
    ident_code(X),
    ident_(Rest).
ident_([]) --> [].

frames([Frame | Frames]) -->
    frame(Frame),
    frames(Frames).
frames([]) --> [].

frame([F | Rest]) -->
    w,
    float(F),
    frame(Rest).
frame([]) --> w, `\n`.

offset_line([X, Y, Z]) -->
    w,
    `OFFSET`,
    whites,
    float(X),
    whites,
    float(Y),
    whites,
    float(Z),
    w,
    `\n`.

channels(Channels) -->
    w,
    `CHANNELS`,
    whites,
    integer(_),
    chanlist(Channels),
    !.

chanlist([C | Rest]) -->
    whites,
    ident(C),
    chanlist(Rest).
chanlist([]) -->
    w, `\n`.

joints_or_end_site(end(X , Y ,Z)) -->
    end_site(X, Y, Z).
joints_or_end_site(joints(Joints)) -->
    joints(Joints).

joints([Joint | Joints]) -->
    joint(Joint),
    joints(Joints).
joints([Joint]) -->
    joint(Joint).

end_site(X, Y, Z) -->
    w,
    `End Site`,
    w,
    `\n`,
    open_curly,
    offset_line([X, Y, Z]),
    close_curly.

joint(joint{
          name: Name,
          offset: Offset,
          channels: Channels,
          joints: Joints
      }) -->
    id_line(`JOINT`, Name),
    open_curly,
    offset_line(Offset),
    channels(Channels),
    joints_or_end_site(Joints),
    close_curly.



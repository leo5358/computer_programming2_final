# Animation Action Guidance

Use the JSON first. These defaults exist only to help infer prompts when an action is underspecified.

## Locomotion

`idle`: subtle breathing, blink, cloth sway. Same silhouette and anchor. No new props.

`walk-right` / `walk-left`: side-view foot cycle. Keep body scale and weapon side consistent. No dust trails unless the JSON explicitly asks and the effect stays attached/readable.

`run-right` / `run-left`: stronger forward lean and wider stride than walk. Avoid smear frames unless the game style explicitly supports them.

## Combat

`guard`: blade or shield raised. The pose must clearly communicate blocking. Keep feet planted.

`parry`: short decisive deflection pose. In easy-mode variants, a tiny hard-edged highlight at weapon contact is allowed when the JSON asks for it.

`attack-light`: quick readable slash. Show anticipation, swing, recovery through pose. Avoid detached motion arcs by default.

`attack-heavy`: slower, heavier wind-up and follow-through. Keep weapon length consistent.

`hurt`: recoil without redesigning the character.

`posture-break`: collapsed or exposed stance suitable for a finisher. Do not add UI icons.

`death`: readable fall/collapse. No gore unless explicitly requested and appropriate for the project.

## Boss / large enemy

Bosses usually need larger cells and fewer, clearer frames. Prefer 128x128 or larger. Preserve scale across rows. Do not shrink the boss to fit a protagonist cell size.

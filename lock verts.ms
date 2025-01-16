try(destroyDialog KeepVerticesLockedRollout) catch()

global KeepVerticesLockedRollout = rollout KeepVerticesLockedRollout "Lock Vertices on Subdivide"
(
    local lockedVertices = #() -- Array to store locked vertex indices
    local originalPositions = #() -- Array to store original vertex positions

    -- UI Elements
    button btnLock "Lock Selected Vertices" width:200
    button btnUnlock "Unlock All Vertices" width:200
    spinner spnIterations "TurboSmooth lvl: " range:[1, 10, 1] type:#integer fieldwidth:50 align:#left
    button btnSubdivide "Subdivide Mesh" width:200

    -- Function to ensure the object is Editable Poly
    fn ensureEditablePoly obj = (
        if classOf obj == Editable_Mesh then (
            convertToPoly obj
        )
        obj
    )

    -- Function to lock selected vertices
    fn lockSelectedVertices obj = (
        obj = ensureEditablePoly obj
        if (classOf obj == Editable_Poly) then (
            local selectedVerts = polyOp.getVertSelection obj as array
            lockedVertices = selectedVerts
            originalPositions = for v in lockedVertices collect polyOp.getVert obj v
            format "Locked Vertices: %\n" lockedVertices
        ) else (
            messageBox "Please select an Editable Poly object."
        )
    )

    -- Function to unlock all vertices
    fn unlockVertices = (
        lockedVertices = #()
        originalPositions = #()
        format "All vertices unlocked.\n"
    )

    -- Function to apply TurboSmooth and restore locked vertices
    fn subdivideWithLockedVerts obj iterations = (
        obj = ensureEditablePoly obj
        if (classOf obj == Editable_Poly) and lockedVertices.count > 0 then (
            -- Store original positions of locked vertices
            local originalPositions = for v in lockedVertices collect polyOp.getVert obj v

            -- Apply TurboSmooth with user-defined iterations
            local tsMod = TurboSmooth iterations:iterations
            modPanel.addModToSelection tsMod ui:on
            max modify mode
            modPanel.setCurrentObject tsMod

            -- Collapse the stack to make the changes permanent
            collapseStack obj
            select obj
            macros.run "Modifier Stack" "Convert_to_Poly"

            -- Restore locked vertices' positions
            for i = 1 to lockedVertices.count do (
                polyOp.setVert obj lockedVertices[i] originalPositions[i]
            )

            update obj
            format "Subdivision applied while keeping vertices locked.\n"
        ) else (
            messageBox "Ensure the object is an Editable Poly and vertices are locked."
        )
    )

    -- Event Handlers
    on btnLock pressed do (
        if selection.count > 0 then lockSelectedVertices selection[1]
        else messageBox "No object selected."
    )

    on btnUnlock pressed do unlockVertices()

    on btnSubdivide pressed do (
        if selection.count > 0 then subdivideWithLockedVerts selection[1] spnIterations.value
        else messageBox "No object selected."
    )
)

createDialog KeepVerticesLockedRollout

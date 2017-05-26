FeatureScript 581;
import(path : "onshape/std/geometry.fs", version : "581.0");

import(path : "d21402a3c4b16091eafa3bf5", version : "9edbfbaa97004ff47fbb037a");




annotation { "Feature Type Name" : "Make CSV" }
export const makeCSV = defineFeature(function(context is Context, id is Id, definition is map)
    precondition
    {
        // Define the parameters of the feature type
    }
    {
        var points = BLOB_DATA.csvData;
        var sketchPoints;
        var sketch1;
        var j;
        var n = 0;
        for (var i = 0; i < size(points); i += 1)
        {
            if (points[i][0] == -1 && points[i][1] == -1)
            {
                sketchPoints = makeArray(points[i][2]);
                // debug(context, size(sketchPoints));
                sketch1 = newSketch(context, id + "sketch" + n, {
                    "sketchPlane" : qCreatedBy(makeId("Top"), EntityType.FACE)
                });
                j = 0;
                continue;
            }
            if (points[i][0] == -2 && points[i][1] == -2)
            {
                skPolyline(sketch1, "polyline", {
                    "points" : sketchPoints
                });
                // println(sketch1);
                skSolve(sketch1);

                // opExtrude(context, id + "extrude" + n , {
                //     "entities" : qSketchRegion(id + "sketch" + n),
                //     "direction" : evOwnerSketchPlane(context, {"entity" : qSketchRegion(id + "sketch" + n)}).normal,
                //     "endBound" : BoundingType.BLIND,
                //     "endDepth" : 2 * millimeter
                // });
                n += 1;
                continue;
            }
            var point = points[i];
            // println(point);
            sketchPoints[j] = vector(point[0], point[1]) * millimeter;
            j += 1;

        }

        for (var i = 0; i < n; i += 1)
        {
            // println(i);
            println(qSketchRegion(id + "sketch" + i ));

            opExtrude(context, id + "extrude" + i , {
                            "entities" : qSketchRegion(id + "sketch" + i),
                            "direction" : evOwnerSketchPlane(context, {"entity" : qSketchRegion(id + "sketch" + i)}).normal,
                            "endBound" : BoundingType.BLIND,
                            "endDepth" : 2 * millimeter
                        });
            // break;
        }



    });

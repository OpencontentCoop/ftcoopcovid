{def $height = cond($block.custom_attributes.map_height,$block.custom_attributes.map_height|wash(),'600')
     $intro_text =  $block.custom_attributes.intro_text|wash()
     $no_result_text = $block.custom_attributes.no_result_text}

<div class="py-4">
    {include uri='design:parts/block_name.tpl'}
    <div class="row invisible" data-mappa_comuni="">
        <div class="my-2 col-md-5">
            <p class="lead">{$intro_text}</p>
            <form>
                <label for="CercaPerComune" class="hide">Seleziona il tuo comune</label>
                <div class="input-group mb-3">
                    <div class="input-group-prepend">
                        <button id="CercaMioComune" class="border border-right-0 px-3 btn btn-outline-secondary" type="button"><i class="fa fa-map-marker fa-2x"></i></button>
                    </div>
                    <select name="CercaPerComune" id="CercaPerComune" class="py-1 px-2 border custom-select form-control-lg">
                        <option class="default">Seleziona il tuo comune...</option>
                    </select>
                </div>
            </form>
            <div id="InfoPerComune"></div>
        </div>
        <div class="my-2 col-md-7 d-none d-md-block">
            <div class="map mappa_comuni" style="width: 100%; height: {$height}px;"></div>
        </div>
        <div id="InfoPerComuneResultTemplate" style="display: none !important;">
            <a href="#" class="mt-4 card rounded border no-after text-decoration-none text-black">
                <div class="card-body">
                    <div class="lead"></div>
                </div>
            </a>
        </div>
    </div>
</div>

{ezcss_require(array(
    'leaflet/leaflet.0.7.2.css'
))}
{ezscript_require(array(
    'leaflet.js',
    'ezjsc::jquery',
    'Leaflet.MakiMarkers.js',
    'jquery.ocdrawmap.js',
    'jquery.opendataTools.js'
))}

{run-once}
<style>
    .mappa_comuni.leaflet-container {ldelim}
        background-color:rgba(255,0,0,0.0);
        outline: 0;
    {rdelim}
    .mappa_comuni:focus, .mappa_comuni :focus{ldelim}
        border: none !important;
        box-shadow:none !important;
    {rdelim}
    .mappa_comuni .leaflet-zoom-animated{ldelim}
        background: transparent !important;
    {rdelim}
    .mappa_comuni .leaflet-tile-pane {ldelim}
        opacity: 0;
    {rdelim}
    .mappa_comuni .leaflet-control-attribution{ldelim}
        visibility: hidden;
    {rdelim}
</style>
<script>
    {literal}
    /******************************************************************************
     * Leaflet.PointInPolygon
     * @author Brian S Hayes (Hayeswise)
     * @license MIT License, Copyright (c) 2017 Brian Hayes ("Hayeswise")
     *
     * Thanks to:<br>
     * Dan Sunday's Winding Number and isLeft C++ implementation - http://geomalgorithms.com/.
     *   Copyright and License: http://geomalgorithms.com/a03-_inclusion.html
     * Leaflet.Geodesic by Kevin Brasier (a.k.a. Fragger)<br>
     */
    (function (L) {
        "use strict";
        L.Polyline.prototype.contains = function (p) {
            //"use strict";
            var rectangularBounds = this.getBounds();  // It appears that this is O(1): the LatLngBounds is updated as points are added to the polygon when it is created.
            var wn;
            if (rectangularBounds.contains(p)) {
                wn = this.getWindingNumber(p);
                return (wn !== 0);
            } else {
                return false;
            }
        };
        L.LatLng.prototype.isLeft = function (p1, p2) {
            return ((p1.lng - this.lng) * (p2.lat - this.lat) -
                (p2.lng - this.lng) * (p1.lat - this.lat));
        };
        L.Polyline.prototype.getWindingNumber = function (p) { // Note that L.Polygon extends L.Polyline
            var i,
                isLeftTest,
                n,
                vertices,
                wn; // the winding number counter
            function flatten(a) {
                var flat;
                flat = ((Array.isArray ? Array.isArray(a) : L.Util.isArray(a)) ? a.reduce(function (accumulator, v, i, array) {
                        return accumulator.concat(Array.isArray(v) ? flatten(v) : v);
                    }, [])
                    : a);
                return flat;
            }

            vertices = this.getLatLngs();
            vertices = flatten(vertices); // Flatten array of LatLngs since multi-polylines return nested array.
            // Filter out duplicate vertices.
            vertices = vertices.filter(function (v, i, array) { // remove adjacent duplicates
                if (i > 0 && v.lat === array[i - 1].lat && v.lng === array[i - 1].lng) {
                    return false;
                } else {
                    return true;
                }
            });
            n = vertices.length;
            // Note that per the algorithm, the vertices (V) must be "a vertex points of a polygon V[n+1] with V[n]=V[0]"
            if (n > 0 && !(vertices[n - 1].lat === vertices[0].lat && vertices[n - 1].lng === vertices[0].lng)) {
                vertices.push(vertices[0]);
            }
            n = vertices.length - 1;
            wn = 0;
            for (i = 0; i < n; i++) {
                isLeftTest = vertices[i].isLeft(vertices[i + 1], p);
                if (isLeftTest === 0) { // If the point is on a line, we are done.
                    wn = 1;
                    break;
                } else {
                    if (isLeftTest !== 0) { // If not a vertex or on line (the C++ version does not check for this)
                        if (vertices[i].lat <= p.lat) {
                            if (vertices[i + 1].lat > p.lat) { // An upward crossing
                                if (isLeftTest > 0) { // P left of edge
                                    wn++; // have a valid up intersect
                                }
                            }
                        } else {
                            if (vertices[i + 1].lat <= p.lat) {// A downward crossing
                                if (isLeftTest < 0) { // P right of edge
                                    wn--; // have a valid down intersect
                                }
                            }
                        }
                    } else {
                        wn++;
                    }
                }
            }
            return wn;
        };

    })(L);

    $(document).ready(function () {
        $('[data-mappa_comuni]').each(function () {
            var that = $(this);
            var selector = that.find('#CercaPerComune');
            var resultContainer = that.find('#InfoPerComune');
            var resultTemplate = that.find('#InfoPerComuneResultTemplate');
            var locationFinder = that.find('#CercaMioComune');
            var NoResultText = "{/literal}{$no_result_text|wash(javascript)}{literal}";
            var Classes = 'spesa_domicilio';

            var osmUrl = 'https://{s}.tile.osm.org/{z}/{x}/{y}.png';
            var osmAttrib = '&copy; <a href="http://openstreetmap.org/copyright">OpenStreetMap</a> contributors';
            var osm = L.tileLayer(osmUrl, {maxZoom: 18, attribution: osmAttrib});

            var map = new L.Map(
                that.find('.map')[0], {
                    scrollWheelZoom: false,
                    zoomControl: false,
                    minZoom: 8,
                    center: new L.LatLng(0, 0), zoom: 13
                }).addLayer(osm);
            var selected = L.featureGroup().addTo(map);
            var perimeters = L.featureGroup().addTo(map);

            var showInfo = function(tagId){
                resultContainer.html('<div class="text-center"><i class="spinner fa a fa-circle-o-notch fa-spin"></i></div>');
                $.opendataTools.find('classes ['+Classes+'] and raw[ezf_df_tag_ids] = '+tagId, function (data) {
                    resultContainer.html('');
                    if (data.totalCount > 0) {
                        $.each(data.searchHits, function () {
                            var template = resultTemplate.clone();
                            var result = $(template.html());
                            result.attr('href', '/content/view/full/'+this.metadata.mainNodeId);
                            result.find('.lead').html(this.data['ita-IT'].testo);
                            resultContainer.append(result);
                        })
                    }else{
                        var template = resultTemplate.clone();
                        var result = $(template.html());
                        result.find('.lead').html(NoResultText);
                        resultContainer.append(result);
                    }
                })
            };

            var hideInfo = function(){
                resultContainer.html('');
            };

            var selectShape = function(feature, layer) {
                selected.clearLayers();
                $.addGeoJSONLayer({
                        type: "FeatureCollection",
                        features: [feature]
                    }, map, selected, null,
                    {
                        color: '{/literal}{header_color()}{literal}',
                        weight: 1,
                        opacity: 1,
                        fillOpacity: 0.7
                    },
                    null,
                    function (feature, layer) {
                        layer.on('click', function (e) {
                            unselectShape();
                            selector.val(selector.find('.default').text());
                        });
                    }
                );
                showInfo(feature.properties.tag_id);
                //map.fitBounds(selected.getBounds());
            };

            var unselectShape = function() {
                selected.clearLayers();
                map.fitBounds(perimeters.getBounds());
                hideInfo();
            };

            var layerContains = function (layer, latLng) {
                var layerHasPoint;
                if ($.isFunction(layer.contains) && layer.contains(latLng)) {
                    layerHasPoint = layer;
                } else if ($.isFunction(layer.eachLayer)) {
                    layer.eachLayer(function (subLayer) {
                        var subLayerHasPoint = layerContains(subLayer, latLng);
                        if (subLayerHasPoint) {
                            layerHasPoint = subLayerHasPoint;
                        }
                    });
                }

                return layerHasPoint;
            };

            $.getJSON('/shapes/comune/_all', function (data) {
                var loaded = 1;
                $.each(data, function () {
                    selector.append('<option value="'+this.features[0].properties.comune+'">'+this.features[0].properties.comune+'</option>');
                    $.addGeoJSONLayer(
                        this,
                        map,
                        perimeters,
                        null,
                        {
                            color: '#666',
                            weight: 2,
                            opacity: 1,
                            fillOpacity: 1,
                            fillColor: '#ffffff'
                        },
                        null,
                        function (feature, layer) {
                            layer.on('click', function (e) {
                                selectShape(feature, layer);
                                selector.val(feature.properties.comune);
                            });
                        }
                    );
                    loaded++;
                    if (loaded >= data.length){
                        that.removeClass('invisible');
                        map.invalidateSize(false);
                        map.fitBounds(perimeters.getBounds());
                    }
                });

                selector.on('change', function (e) {
                    var selected = $(this).val();
                    if (selected === ''){
                        unselectShape();
                    }else {
                        for (var i in perimeters._layers) {
                            if (perimeters._layers[i].feature.properties.comune === selected) {
                                selectShape(perimeters._layers[i].feature, perimeters._layers[i]);
                                break;
                            }
                        }
                    }
                });

                locationFinder.on('click', function (e) {
                    map.locate(
                        {setView: false, watch: false}
                    ).on('locationfound', function (e) {
                        var latLng = new L.LatLng(e.latitude, e.longitude);
                        perimeters.eachLayer(function (layer) {
                            var layerHasPoint = layerContains(layer, latLng);
                            if (layerHasPoint) {
                                selectShape(layer.feature, layer);
                                selector.val(layer.feature.properties.comune);
                            }
                        });

                        map.off('locationfound');
                    }).on('locationerror', function (e) {
                        alert("Verifica le preferenze di localizzazione");
                        map.off('locationerror');
                    });
                    e.preventDefault();
                });
            });
        });
    });
    {/literal}
</script>
{run-once}
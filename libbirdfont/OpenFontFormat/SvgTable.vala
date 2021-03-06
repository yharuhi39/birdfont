/*
	Copyright (C) 2015 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using B;
using SvgBird;

namespace BirdFont {

public class SvgTable : OtfTable {
	
	int glyphs_in_table = 0;
	Gee.ArrayList<SvgTableEntry> entries;

	public SvgTable () {
		id = "SVG ";
		entries = new Gee.ArrayList<SvgTableEntry> ();
	}
	
	public bool has_glyphs () {
		return glyphs_in_table > 0;
	}

	public void process (GlyfTable glyf_table) throws GLib.Error {
		Font font = OpenFontFormatWriter.get_current_font ();
		GlyphCollection? glyph_collection;
		GlyphCollection glyphs;
		int gid;
		Gee.ArrayList<EmbeddedSvg> embedded_svg;
		
		for (int index = 0; index < font.length (); index++) {		
			glyph_collection = font.get_glyph_collection_index (index);
			
			if (glyph_collection != null) {
				glyphs = (!) glyph_collection;
				embedded_svg = get_embedded_svg (glyphs);
				
				if (embedded_svg.size > 0) {
					gid = glyf_table.get_gid (glyphs.get_name ());
					
					StringBuilder svg = new StringBuilder ();
					svg.append ("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n");

					svg.append ("""<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">""");
					svg.append ("\n\n");
					
					svg.append ("<g id=");
					svg.append ("\"");
					svg.append ("glyph");
					svg.append (@"$gid");
					svg.append ("\" >");
		
					foreach (EmbeddedSvg embedded in embedded_svg) {
						svg.append ("<g ");
						
						// scale the internal coordinates from 100 units per em to the 
						// number of units per em in this font and move the glyph
						// in to the em box
						Glyph glyph = glyphs.get_current ();
						double scale = HeadTable.UNITS;
						double x = embedded.x - glyph.left_limit;
						double y = font.base_line - embedded.y;
						svg.append (@"transform=\"scale($scale) translate($x, $y)\"");
						
						svg.append (">");
						svg.append ("\n\n");

						append_svg_glyph (svg, embedded, glyphs);

						svg.append ("</g>\n");
						svg.append ("\n\n");
					}

					svg.append ("</g>\n");
					svg.append ("</svg>");
					
					SvgTableEntry entry;
					entry = new SvgTableEntry ((uint16) gid, svg.str);
					entries.add (entry);

					glyphs_in_table++;
				}
			}
		}

		process_svg_data ();
	}
	
	Gee.ArrayList<EmbeddedSvg> get_embedded_svg (GlyphCollection glyphs) {
		Gee.ArrayList<EmbeddedSvg> svg = new Gee.ArrayList<EmbeddedSvg> ();
		PathList path_list = new PathList ();
		
		foreach (SvgBird.Object object in glyphs.get_current ().get_visible_objects ()) {
			if (object is EmbeddedSvg) {
				svg.add ((EmbeddedSvg) object);
			} else if (object is PathObject) {
				Path path = ((PathObject) object).get_path ();
				
				if (path.stroke > 0) {
					path_list.append (path.get_completed_stroke ());
				} else {
					path_list.add (path);
				}
			}
		}

		if (path_list.paths.size > 0) {
			EmbeddedSvg svg_data = generate_svg (path_list, glyphs);
			svg.add (svg_data);
		}
		
		return svg;
	}
		
	void append_svg_glyph (StringBuilder svg, EmbeddedSvg embedded, GlyphCollection glyphs) {
		Gee.ArrayList<Tag> layer_content;
		Gee.ArrayList<Tag> svg_tags;
		Gee.ArrayList<Tag> meta;
		XmlParser xml;
		Tag svg_root_tag;
		Font font;
		string svg_data;
		
		svg_data = embedded.get_transformed_svg_data ();
		font = OpenFontFormatWriter.get_current_font ();
		
		layer_content = new Gee.ArrayList<Tag> ();
		svg_tags = new Gee.ArrayList<Tag> ();
		meta = new Gee.ArrayList<Tag> ();
		xml = new XmlParser (svg_data);
		 
		if (!xml.validate ()) {
			warning("Invalid SVG data in TTF table.");
			return;
		}
		
		svg_root_tag = xml.get_root_tag ();
		
		foreach (Tag tag in svg_root_tag) {
			string name = tag.get_name();

			if (name == "defs") {
				svg_tags.add (tag);
			} else if (name == "style") {
				svg_tags.add (tag);
			} else if (name == "metadata") {
				meta.add (tag);
			} else if (name == "sodipodi") {
				meta.add (tag);
			} else {
				layer_content.add (tag);
			}
		}
		
		svg.append ("<");
		svg.append (svg_root_tag.get_name ());
		svg.append (" ");
		append_tag_attributes (svg, svg_root_tag);
		svg.append (">");

		foreach (Tag tag in svg_tags) {
			append_tag (svg, tag);
		}
		
		foreach (Tag tag in layer_content) {
			append_tag (svg, tag);
		}
				
		svg.append ("</");
		svg.append (svg_root_tag.get_name ());
		svg.append (">\n");		
	}

	public void append_tag (StringBuilder svg, Tag tag) {
		string content = tag.get_content ();
		
		svg.append ("<");
		svg.append (tag.get_name ());
		
		svg.append (" ");
		append_tag_attributes (svg, tag);
		
		if (content == "") {
			svg.append (" /");
		}
		
		svg.append (">");
		
		if (content != "") {
			svg.append (content);
			svg.append ("</");
			svg.append (tag.get_name ());
			svg.append (">");
		}
	}
	
	public void append_tag_attributes (StringBuilder svg, Tag tag) {
		bool first = true;
		
		foreach (Attribute attribute in tag.get_attributes ()) {
			string ns = attribute.get_namespace ();
			
			if (!first) {
				svg.append (" ");
			}
						
			if (ns != "") {
				svg.append (ns);
				svg.append (":");
			}
			
			svg.append (attribute.get_name ());
			svg.append ("=");
			svg.append ("\"");
			svg.append (attribute.get_content ());
			svg.append ("\"");
			
			first = false;
		}
	}
	
	public void process_svg_data () throws GLib.Error {
		FontData fd = new FontData ();
		
		int32 svg_index_offset = 10;
		
		fd.add_ushort (0); // version
		fd.add_ulong (svg_index_offset);
		fd.add_ulong (0); // reserved
		
		uint32 document_offset = 2 + 12 * entries.size;
		
		// SVG Documents Index
		fd.add_ushort ((uint16) entries.size);
		
		foreach (SvgTableEntry entry in entries) {
			fd.add_ushort (entry.glyph_id); // start
			fd.add_ushort (entry.glyph_id); // end
			fd.add_ulong (document_offset); // offset
			fd.add_ulong (entry.data.length_with_padding ()); // length
			document_offset += entry.data.length_with_padding ();
		}

		foreach (SvgTableEntry entry in entries) {
			fd.append (entry.data);
		}
			
		fd.pad ();
		
		this.font_data = fd;
	}

	public EmbeddedSvg generate_svg (PathList paths, GlyphCollection glyphs) {
		StringBuilder svg = new StringBuilder ();
		
		svg.append ("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n");
		svg.append ("""<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">""");
		svg.append ("\n");
		
		Glyph g = glyphs.get_current ();
		Font font = OpenFontFormatWriter.get_current_font ();
		svg.append (@"<g transform=\"translate(0, $(font.get_height ()))\">\n");
		svg.append (@"<g transform=\"translate($(-g.left_limit), $(-font.base_line))\">\n");

		svg.append ("""<path style="fill:#000000;fill-opacity:1;" """);
		svg.append ("d=\"");

		foreach (Path p in paths.paths) {
			p.add_hidden_double_points ();
			
			int i = 0;
			EditPoint? n = null;
			EditPoint m;
			
			if (p.points.size < 2) {
				return new EmbeddedSvg (new SvgDrawing ());
			}

			p.create_list ();
				
			foreach (var e in p.points) {
				if (i == 0) {
					add_abs_start (e, svg);
					i++;
					n = e;
					continue;
				}
				
				m = (!) n;

				add_abs_next (m, e, svg);
				
				n = e;
				i++;
			}

			if (!p.is_open ()) {
				m = p.get_first_point ();	
				add_abs_next ((!) n, m, svg);
				close_path (svg);
			}
		}
		svg.append ("\" />\n");
		
		svg.append ("</g>\n");
		svg.append ("</g>\n");
		svg.append ("</svg>\n");

		EmbeddedSvg embedded = new EmbeddedSvg (new SvgDrawing ());
		embedded.x = g.left_limit;
		embedded.y = font.get_height ();
		embedded.svg_data = svg.str;

		return embedded;
	}

	public static void add_abs_next (EditPoint start, EditPoint end, StringBuilder svg) {
		if (start.right_handle.type == PointType.LINE_QUADRATIC) {
			add_abs_line_to (start, end, svg);
		} else if (start.right_handle.type == PointType.LINE_CUBIC && end.left_handle.type == PointType.LINE_CUBIC) {
			add_abs_line_to (start, end, svg);
		} else if (end.left_handle.type == PointType.QUADRATIC || start.right_handle.type == PointType.QUADRATIC) {
			add_quadratic_abs_path (start, end, svg);
		} else if (end.left_handle.type == PointType.DOUBLE_CURVE || start.right_handle.type == PointType.DOUBLE_CURVE) {
			add_double_quadratic_abs_path (start, end, svg);
		} else {
			add_cubic_abs_path (start, end, svg);
		}
	}

	private static void add_abs_start (EditPoint ep, StringBuilder svg) {		
		svg.append_printf ("M");		
		svg.append_printf ("%s ",  round (ep.x));
		svg.append_printf ("%s ",  round (-ep.y));
	}

	public static void close_path (StringBuilder svg) {
		svg.append ("z");
	}	
	
	private static void add_abs_line_to (EditPoint start, EditPoint stop, StringBuilder svg) {
		svg.append ("L");	
		svg.append_printf ("%s ", round (stop.x));
		svg.append_printf ("%s ", round (-stop.y));	
	}
	
	private static void add_double_quadratic_abs_path (EditPoint start, EditPoint end, StringBuilder svg) {
		EditPoint middle;
		double x, y;
		
		x = start.get_right_handle ().x + (end.get_left_handle ().x - start.get_right_handle ().x) / 2;
		y = start.get_right_handle ().y + (end.get_left_handle ().y - start.get_right_handle ().y) / 2;
		
		middle = new EditPoint (x, y, PointType.QUADRATIC);
		middle.right_handle = end.get_left_handle ().copy ();
		
		add_quadratic_abs_path (start, middle, svg);
		add_quadratic_abs_path (middle, end, svg);
	}
		
	private static void add_quadratic_abs_path (EditPoint start, EditPoint stop, StringBuilder svg) {
		// cubic path
		svg.append_printf ("Q");

		svg.append_printf ("%s ", round (start.get_right_handle ().x));
		svg.append_printf ("%s ", round (-start.get_right_handle ().y));
		
		svg.append_printf ("%s ", round (stop.x));
		svg.append_printf ("%s ", round (-stop.y));
	}
			
	private static void add_cubic_abs_path (EditPoint start, EditPoint stop, StringBuilder svg) {
		// cubic path
		svg.append_printf ("C");

		svg.append_printf ("%s ", round (start.get_right_handle ().x));
		svg.append_printf ("%s ", round (-start.get_right_handle ().y));

		svg.append_printf ("%s ", round (stop.get_left_handle ().x));
		svg.append_printf ("%s ", round (-stop.get_left_handle ().y));
		
		svg.append_printf ("%s ", round (stop.x));
		svg.append_printf ("%s ", round (-stop.y));
	}

}

}

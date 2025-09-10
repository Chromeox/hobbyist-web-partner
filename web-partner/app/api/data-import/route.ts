import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { parse } from 'csv-parse/sync'; // Using synchronous parser for simplicity in this example

// Initialize Supabase client with service role key for elevated privileges
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

export async function POST(request: Request) {
  try {
    // --- Authentication/Authorization (Crucial for Production) ---
    // In a real application, you would verify the user's identity and permissions
    // to ensure only authorized studios can upload data.
    // For example, check for a valid session token or API key.

    const formData = await request.formData();
    const file = formData.get('file') as File;

    if (!file) {
      return NextResponse.json({ error: 'No file uploaded' }, { status: 400 });
    }

    // Read the file content as text
    const fileContent = await file.text();

    // Parse the CSV content
    // Assuming the CSV has headers and is comma-delimited
    const records = parse(fileContent, {
      columns: true, // Treat the first row as column headers
      skip_empty_lines: true,
    });

    // --- Data Validation and Transformation (Crucial) ---
    // Before inserting into Supabase, you would typically:
    // 1. Validate each record against your schema (e.g., required fields, data types).
    // 2. Transform data to match your database table structure.
    // 3. Handle potential duplicates or conflicts.
    // 4. Associate the data with the uploading studio/instructor (e.g., add a 'studio_id' column).

    // For demonstration, let's assume we're importing 'classes' data
    // and the CSV columns match the 'classes' table in Supabase.
    // You would need to adapt this based on the actual CSV content and target table.

    // Example: Insert records into a 'imported_classes' table
    const { data, error } = await supabase.from('imported_classes').insert(records);

    if (error) {
      console.error('Supabase insert error:', error);
      return NextResponse.json({ error: 'Failed to import data to database' }, { status: 500 });
    }

    return NextResponse.json({ message: 'CSV imported successfully', recordsInserted: records.length }, { status: 200 });

  } catch (error: any) {
    console.error('Error processing CSV upload:', error);
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}

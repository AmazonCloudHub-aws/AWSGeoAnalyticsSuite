import obspy
import boto3


def process_seismic_data(seismic_file):
    """
    Process seismic data using ObsPy.

    Args:
        seismic_file (str): Path to the seismic data file.

    Returns:
        dict: Dictionary containing processed seismic data and metadata.
    """
    # Read seismic data from file
    st = obspy.read(seismic_file)

    # Perform processing steps (example: filtering, plotting, etc.)
    # Here, we'll just print some basic information about the data
    num_traces = len(st)
    duration = st[0].stats.endtime - st[0].stats.starttime
    sampling_rate = st[0].stats.sampling_rate

    # Prepare metadata
    metadata = {
        "num_traces": num_traces,
        "duration": duration,
        "sampling_rate": sampling_rate,
    }

    return {"data": st, "metadata": metadata}


def upload_to_s3(processed_data, bucket_name, object_key):
    """
    Upload processed seismic data to an S3 bucket.

    Args:
        processed_data (dict): Processed seismic data and metadata.
        bucket_name (str): Name of the S3 bucket.
        object_key (str): Key for the object in the S3 bucket.
    """
    # Initialize S3 client
    s3_client = boto3.client("s3")

    # Upload data to S3 bucket
    s3_client.upload_file(processed_data["data"].write("temp.mseed", format="mseed", byteorder='<'), bucket_name, object_key)

    print(f"Seismic data uploaded to S3 bucket '{bucket_name}' with object key '{object_key}'")


# Example usage
seismic_file_path = "path/to/seismic_data.mseed"
processed_data = process_seismic_data(seismic_file_path)

# Bucket name and object key
bucket_name = "your-s3-bucket-name"  # Replace with your S3 bucket name
object_key = "processed_data.mseed"  # Specify the key for the uploaded object

# Upload processed data to S3
upload_to_s3(processed_data, bucket_name, object_key)

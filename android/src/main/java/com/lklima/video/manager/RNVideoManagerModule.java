
package com.lklima.video.manager;

import com.coremedia.iso.boxes.Container;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import android.util.Log;
import com.facebook.react.bridge.ReadableArray;

import com.googlecode.mp4parser.authoring.Movie;
import com.googlecode.mp4parser.authoring.Track;
import com.googlecode.mp4parser.authoring.container.mp4.MovieCreator;
import com.googlecode.mp4parser.authoring.tracks.AppendTrack;
import com.googlecode.mp4parser.authoring.builder.DefaultMp4Builder;
import com.googlecode.mp4parser.authoring.tracks.CroppedTrack;
import com.googlecode.mp4parser.util.Matrix;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.lang.Math;
import java.util.Arrays;

import android.media.MediaMetadataRetriever;
import android.util.Log;
import android.net.Uri;
import android.media.MediaPlayer;

public class RNVideoManagerModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public RNVideoManagerModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @ReactMethod
  public void getVideoDuration(String filePath, Promise promise) {
    try {
      MediaMetadataRetriever retriever = new MediaMetadataRetriever();
      retriever.setDataSource(filePath);

      String durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
      long duration = Long.parseLong(durationStr);

      // Convert duration from milliseconds to seconds
      double durationSeconds = duration / 1000.0;
      promise.resolve(durationSeconds);

    } catch (Exception e) {
      Log.e("getVideoDuration", "Error: " + e.getMessage());
      promise.reject("get_video_duration_error", e.getMessage());
    }
  }

  // trim the video by taking input file url, start time and end time, return a
  // temp video file url
  @ReactMethod
  public void trim(String videoFile, double startTime, double endTime, Promise promise) {
    try {
      File src = new File(videoFile.replaceFirst("file://", ""));
      File output = new File(reactContext.getApplicationContext().getCacheDir(), "trimmed_output.mp4");

      Movie movie = MovieCreator.build(src.getAbsolutePath());
      List<Track> tracks = movie.getTracks();
      movie.setTracks(new LinkedList<Track>());

      double startTimeInSeconds = startTime;
      double endTimeInSeconds = endTime;

      boolean timeCorrected = false;

      for (Track track : tracks) {
        if (track.getSyncSamples() != null && track.getSyncSamples().length > 0) {
          if (timeCorrected) {
            throw new RuntimeException(
                "The startTime has already been corrected by another track with SyncSample. Not Supported.");
          }
          startTimeInSeconds = correctTimeToSyncSample(track, startTimeInSeconds, false);
          endTimeInSeconds = correctTimeToSyncSample(track, endTimeInSeconds, true);
          timeCorrected = true;
        }
      }

      for (Track track : tracks) {
        long startSample = getSampleAtTime(track, startTimeInSeconds);
        long endSample = getSampleAtTime(track, endTimeInSeconds);

        movie.addTrack(new CroppedTrack(track, startSample, endSample));
      }

      Container out = new DefaultMp4Builder().build(movie);
      FileChannel fc = new FileOutputStream(output).getChannel();
      out.writeContainer(fc);
      fc.close();

      promise.resolve(output.getAbsolutePath());
    } catch (IOException e) {
      e.printStackTrace();
      promise.reject("trim_error", e.getMessage());
    }
  }

  private long getSampleAtTime(Track track, double timeInSeconds) {
    long sampleIndex = 0;
    double currentTime = 0;

    for (int i = 0; i < track.getSampleDurations().length; i++) {
      currentTime += (double) track.getSampleDurations()[i] / (double) track.getTrackMetaData().getTimescale();
      if (currentTime >= timeInSeconds) {
        sampleIndex = i;
        break;
      }
    }

    return sampleIndex;
  }

  private double correctTimeToSyncSample(Track track, double cutHere, boolean next) {
    double[] timeOfSyncSamples = new double[track.getSyncSamples().length];
    long currentSample = 0;
    double currentTime = 0;

    for (int i = 0; i < track.getSampleDurations().length; i++) {
      if (Arrays.binarySearch(track.getSyncSamples(), currentSample + 1) >= 0) {
        timeOfSyncSamples[Arrays.binarySearch(track.getSyncSamples(), currentSample + 1)] = currentTime;
      }
      currentTime += (double) track.getSampleDurations()[i] / (double) track.getTrackMetaData().getTimescale();
      currentSample++;
    }

    double previous = 0;
    for (double timeOfSyncSample : timeOfSyncSamples) {
      if (timeOfSyncSample > cutHere) {
        if (next) {
          return timeOfSyncSample;
        } else {
          return previous;
        }
      }
      previous = timeOfSyncSample;
    }

    return timeOfSyncSamples[timeOfSyncSamples.length - 1];
  }

  @ReactMethod
  public void merge(ReadableArray videoFiles, Promise promise) {

    List<Movie> inMovies = new ArrayList<Movie>();

    for (int i = 0; i < videoFiles.size(); i++) {
      String videoUrl = videoFiles.getString(i).replaceFirst("file://", "");

      try {
        inMovies.add(MovieCreator.build(videoUrl));
      } catch (IOException e) {
        promise.reject(e.getMessage());
        e.printStackTrace();
      }
    }

    List<Track> videoTracks = new LinkedList<Track>();
    List<Track> audioTracks = new LinkedList<Track>();

    for (Movie m : inMovies) {
      for (Track t : m.getTracks()) {
        if (t.getHandler().equals("soun")) {
          audioTracks.add(t);
        }
        if (t.getHandler().equals("vide")) {
          videoTracks.add(t);
        }
      }
    }

    Movie result = new Movie();

    if (!audioTracks.isEmpty()) {
      try {
        result.addTrack(new AppendTrack(audioTracks.toArray(new Track[audioTracks.size()])));
      } catch (IOException e) {
        promise.reject(e.getMessage());
        e.printStackTrace();
      }
    }
    if (!videoTracks.isEmpty()) {
      try {
        result.addTrack(new AppendTrack(videoTracks.toArray(new Track[videoTracks.size()])));
      } catch (IOException e) {
        promise.reject(e.getMessage());
        e.printStackTrace();
      }
    }

    Container out = new DefaultMp4Builder().build(result);
    FileChannel fc = null;

    try {

      Long tsLong = System.currentTimeMillis() / 1000;
      String ts = tsLong.toString();

      String outputVideo = reactContext.getApplicationContext().getCacheDir().getAbsolutePath() + "output_" + ts
          + ".mp4";

      fc = new RandomAccessFile(String.format(outputVideo), "rw").getChannel();

      Log.d("VIDEO", String.valueOf(fc));
      out.writeContainer(fc);
      fc.close();
      promise.resolve(outputVideo);
    } catch (FileNotFoundException e) {
      e.printStackTrace();
      promise.reject(e.getMessage());
    } catch (IOException e) {
      e.printStackTrace();
      promise.reject(e.getMessage());
    }

  }

  @Override
  public String getName() {
    return "RNVideoManager";
  }
}

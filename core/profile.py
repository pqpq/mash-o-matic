"""
Mash-o-matiC Core.
https://github.com/pqpq/beer-o-tron

Profile class
"""

import json
import math
from pathlib import Path
from datetime import datetime, timedelta
from os import scandir


def json_from_file(filepath, logger):
    try:
        with open(filepath, "r") as file:
            return json.load(file)
    except:
        logger.error("Problem reading " + filepath)
        logger.error("details: " + str(sys.exc_info()[1]))
    return None


class Profile():
    """
    Encapsulate a time/temperature profile.

    The profile is the ideal time/temperature relationship that the script
    will try to maintain by measuring the mash temperature and heating it
    when necessary.

    There are two types of profile: preset and hold.

    Preset are created by the user and have an arbitrary number of steps.

    Hold are created by the script, from 'set' messages sent from the GUI
    and are a representation in Profile form of what the user has asked for.
    The simples hold profile has a start temperature followed by a rest
    which extends as time passes.

    Member variables:

    file_path   is the JSON file describing the profile.
                For preset profiles this will have been written by the user.
                For hold profiles this is generated by the code.
    graph_data_path
                is the path of the output file generated when we convert
                the JSON into a time/temperature CSV file for gnuplot.
                For presets this is done once, since the whole profile is
                already known. For a hold profile, the Profile is updated
                as time passes, so the graph needs to be updated frequently
                to keep in sync.
    profile     The JSON representation.
    start_time  When the profile was created. For hold profiles, this is
                used to maintain the rolling rest that terminates the
                profile.
    last_change The last time the hold profile was changed.
    logger      A Logger
    hold_rest_minutes
                How long the rolling rest step should extend into the
                future when we're holding a set temperature.
    """
    def __init__(self, file_path, graph_data_path, logger):
        self.file_path = file_path
        self._graph_data_path = graph_data_path
        self.start_time = datetime.now()
        self.last_change = self.start_time
        self.logger = logger
        self.hold_rest_minutes = 0
        if Path(file_path).exists():
            self.profile = json_from_file(self.file_path, self.logger)

    def create_hold_profile(self, temperature, hold_rest_minutes):
        self.hold_rest_minutes = hold_rest_minutes
        self.profile = {"name": "Hold", "description": "Automatically generated."}
        self.profile["steps"] = [{"start": temperature}, {"rest": hold_rest_minutes}]
        self.__update_generated_files()

    def graph_data_path(self):
        return self._graph_data_path

    def __rest_minutes(self):
        seconds = (datetime.now() - self.last_change).total_seconds()
        return int(round(seconds / 60.0))

    def __update_generated_files(self):
        self.write()
        self.write_plot()

    def __update_rest_step(self, additional_minutes = 0):
        last_step = self.profile["steps"][-1]
        last_step["rest"] = self.__rest_minutes() + additional_minutes

    def update_rest(self):
        self.__update_rest_step(self.hold_rest_minutes)
        self.__update_generated_files()

    def change_set_point(self, temperature):
        self.__update_rest_step()
        self.last_change = datetime.now()
        self.profile["steps"].append({"jump": temperature})
        self.profile["steps"].append({"rest": self.hold_rest_minutes})
        self.__update_generated_files()

    def write(self):
        with open(self.file_path, "w+") as f:
            json.dump(self.profile, f, indent=4)

    def temperature_at(self, seconds):
        step_start_temperature = 0
        step_start_seconds = 0

        step_end_temperature = math.nan
        step_end_seconds = 0

        elapsed_seconds = 0

        print("Profile.temperature_at(",seconds,"")
        for step in self.profile["steps"]:
            keys = list(step)
            print(str(step))
            if len(keys) > 0:
                step_duration = 0
                if keys[0] == "start":
                    step_start_temperature = step["start"]
                    step_end_temperature = step_start_temperature
                if keys[0] == "rest":
                    step_start_temperature = step_end_temperature
                    step_duration = step["rest"] * 60
                if keys[0] == "ramp":
                    step_start_temperature = step_end_temperature
                    step_end_temperature = step["to"]
                    step_duration = step["ramp"] * 60
                if keys[0] == "mashout":
                    step_start_temperature = step["mashout"]
                    step_end_temperature = step_start_temperature
                    step_duration = 99999
                if keys[0] == "jump":
                    step_start_temperature = step["jump"]
                    step_end_temperature = step_start_temperature
                    step_duration = 0

                step_start_seconds = elapsed_seconds
                elapsed_seconds = elapsed_seconds + step_duration
                step_end_seconds = elapsed_seconds
                print("  step_start_seconds", step_start_seconds)
                print("  step_start_temperature", step_start_temperature)
                print("  step_end_seconds", step_end_seconds)
                print("  step_end_temperature", step_end_temperature)
                if (step_start_seconds <= seconds) and (seconds <= step_end_seconds):
                    interpolated_temperature = step_start_temperature
                    if step_duration != 0:
                        proportion = (seconds - step_start_seconds) / step_duration
                        interpolated_temperature = step_start_temperature + (step_end_temperature - step_start_temperature) * proportion
                        print("  INTERPOLATED", interpolated_temperature)
                    return interpolated_temperature

        return step_end_temperature

    def write_plot(self):
        """ Write a file containing gnuplot data for the profile."""
        with open(self._graph_data_path, "w+") as f:
            run_time = self.start_time
            f.write("Time, Temperature\n")
            temperature = 0
            for step in self.profile["steps"]:
                keys = list(step)
                if len(keys) > 0:
                    if keys[0] == "start":
                        temperature = step["start"]
                    if keys[0] == "rest":
                        run_time += timedelta(minutes = step["rest"])
                    if keys[0] == "ramp":
                        run_time += timedelta(minutes = step["ramp"])
                        temperature = step["to"]
                    if keys[0] == "mashout":
                        temperature = step["mashout"]
                        time = run_time.strftime("%H:%M:%S, ")
                        f.write(time + str(temperature) + "\n")
                        run_time += timedelta(minutes = 10)
                    if keys[0] == "jump":
                        temperature = step["jump"]

                    time = run_time.strftime("%H:%M:%S, ")
                    f.write(time + str(temperature) + "\n")
                else:
                    logger.error("Can't make sense of " + str(step))

    @staticmethod
    def get_list(profiles_folder, logger):
        """ Get a list of objects describing all the profiles in the profiles_folder."""
        profile_list = []
        with scandir(profiles_folder) as it:
            for entry in it:
                if entry.is_file():
                    filepath = profiles_folder + entry.name
                    profile = json_from_file(filepath, logger)
                    if profile is not None:
                        try:
                            profile_list.append({"filepath":filepath, "name":profile["name"], "description":profile["description"]})
                        except AttributeError:
                            logger.error("Missing attributes in " + filepath)
                            logger.error(str(profile))
        return profile_list


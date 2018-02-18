/**
 * Created by dsarangi on 1/30/17.
 */

import org.apache.commons.cli.*;
import java.util.Comparator;


public class NzCmdlineOptions {

    private Options options;
    private CommandLine commands;

    //Update these sequence (used for printing) if new options are added
    private final String OPTION_SEQUENCE = "hsrdupqiol";
    public  NzCmdlineOptions(String[] args){
        options = new Options();
        options.addOption("h", false, "Show help");
        options.addOption("s", true , "Netezza Server Address");
        options.addOption("d", true , "Database on Netezza to Connect");
        options.addOption("u", true , "Masked User Name. Do not provide password in clear text");
        options.addOption("p", true , "Masked Password. Do not provide password in clear text");
        options.addOption("r", true , "Netezza Server port to connect");
        options.addOption("o", true , "Output file path, optional");
        options.addOption("l", true , "Output delimiter");
        options.addOption("q", true , "Query to run. [Use one of -q or -i options]");
        options.addOption("i", true , "Input query file. [Use one of -q or -i options]");

        //Parse command line
        CommandLineParser parser = new DefaultParser();

        //Validate command line options
        try{
            //Parse options
            commands = parser.parse(options, args);

            //Check presence of all required parameters
            if( commands.hasOption('h')) help("Showing help:");

            if(!commands.hasOption('s')) help("'-s' option is missing. Provide server address");
            if(!commands.hasOption('d')) help("'-d' option is missing. Provide database name");
            if(!commands.hasOption('u')) help("'-u' option is missing. Provide encrypted user name");
            if(!commands.hasOption('p')) help("'-p' option is missing. Provide encrypted password");
            if(!commands.hasOption('r')) help("'-r' option is missing. Provide server port to connect");
            if(!commands.hasOption('q') && !commands.hasOption('i')) help("'-i' and 'q' options are missing. Provide provide query or query file");
            if(commands.hasOption('q') && commands.hasOption('i')) help("Both '-i' and 'q' options are present. Provide provide query or query file");

        }catch (ParseException e){
            help("Could not parse command line parameters!");
        }
    }

    //Get option values
    public String getOptionValue(String var){
        if(!commands.hasOption(var)) throw new RuntimeException("The option " + var + " is not available" );
        return commands.getOptionValue(var);
    }

    //Get decrypted option values. Used for username and password
    public String getOptionValueDecrypted(String var){
        if(!commands.hasOption(var)) throw new RuntimeException("The option " + var + " is not available" );
        Encrypter e= new Encrypter(Constants.ENCRYPTSTR);
        String val = null;
        try {
            val = e.decrypt(commands.getOptionValue(var));
            return val;
        }catch(Exception ex){
            System.err.println("Some error happened decrypting the string");
            System.err.println(ex.getMessage());
            System.exit(-1);
        }

        return val;
    }

    //Check if a option is present
    public boolean hasOption(String var){
        return commands.hasOption(var);
    }

    //Utility to print message
    private void help(String msg) {
        System.err.println(msg);
        HelpFormatter formatter = new HelpFormatter();
        formatter.setOptionComparator(new OptionComparator<>());
        formatter.printHelp("GetQueryResult", options);
        System.exit(0);
    }

    //Option comparator class for printing help in right sequence.
    class OptionComparator<T extends Option> implements Comparator<T> {
        public int compare(T o1, T o2) {
            return OPTION_SEQUENCE.indexOf(o1.getOpt()) - OPTION_SEQUENCE.indexOf(o2.getOpt());
        }
    }

}
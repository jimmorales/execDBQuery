import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;


public class GetNZQueryResult {


    public static void main(String[] args) {
        //Parse command line parameters
        NzCmdlineOptions co = new NzCmdlineOptions(args);
        NzDbManager db = new NzDbManager(
                co.getOptionValue("s"),
                co.getOptionValue("r"),
                co.getOptionValue("d"),
                co.getOptionValueDecrypted("u"),
                co.getOptionValueDecrypted("p")
        );

        //Get the delimiter
        String delim = Constants.DELIMITER;
        if(co.hasOption("l")) delim = co.getOptionValue("l");

        //Get the query
        String query = null;
        if(co.hasOption("q")){
            query = co.getOptionValue("q");
        }else{
            try {
                query = new String(Files.readAllBytes(Paths.get(co.getOptionValue("i"))));
            }catch (IOException e){
                System.err.println("Some exception occured while reading query file");
                System.exit(-1);
            }
        }

        if(co.hasOption("o")){
            db.printQueryResult(query, delim, co.getOptionValue("o"));
        }else {
            db.printQueryResult(query, delim);

        }
        db.closeAll();
    }


}